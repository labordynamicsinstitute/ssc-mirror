{smcl}
{* *! xtccecoint.sthlp — v1.0.0 — 2026-05-11}{...}
{vieweralsosee "xtbreakcoint" "help xtbreakcoint"}{...}
{vieweralsosee "cupfm" "help cupfm"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "xtcce" "help xtcce"}{...}
{vieweralsosee "xtnumfac" "help xtnumfac"}{...}
{vieweralsosee "xtcd2" "help xtcd2"}{...}
{viewerjumpto "Syntax" "xtccecoint##syntax"}{...}
{viewerjumpto "Description" "xtccecoint##description"}{...}
{viewerjumpto "Background" "xtccecoint##background"}{...}
{viewerjumpto "Models" "xtccecoint##models"}{...}
{viewerjumpto "Options" "xtccecoint##options"}{...}
{viewerjumpto "Interpretation" "xtccecoint##interpretation"}{...}
{viewerjumpto "Critical Values" "xtccecoint##critval"}{...}
{viewerjumpto "Examples" "xtccecoint##examples"}{...}
{viewerjumpto "Stored results" "xtccecoint##stored"}{...}
{viewerjumpto "Author" "xtccecoint##author"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtccecoint} {hline 2}}Panel CCE Cointegration Test
(Banerjee & Carrion-i-Silvestre, 2017){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtccecoint} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt model(#)}}deterministic specification: 0, 1, or 2; default is {bf:2}{p_end}
{synopt:{opt nfact:ors(#)}}number of common factors r; default is k+1 (rank equality){p_end}
{synopt:{opt method(#)}}cross-section dependence approach: 0=OLS, 1=CCE; default is {bf:1}{p_end}
{synopt:{opt opt:ion(#)}}CCE estimator: 0=individual, 1=MG, 2=PCCE; default is {bf:2}{p_end}
{synopt:{opt plag:s(#)}}AR lag order for CADF regression; default is {bf:1}{p_end}
{synopt:{opt notrun:cate}}disable truncation of individual t-ratios{p_end}

{syntab:Output}
{synopt:{opt plot}}produce diagnostic visualization plots{p_end}
{synopt:{opt notable}}suppress output tables{p_end}
{synopt:{opt saving(string)}}filename stem for saved graphs{p_end}
{synopt:{opt noisily}}display verbose Mata computation output{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtccecoint} implements the {bf:CADF_P panel cointegration test} proposed by
Banerjee and Carrion-i-Silvestre (2017). The test assesses whether a set of
I(1) variables in a panel are cointegrated, while accounting for {bf:cross-section
dependence} using the {bf:Common Correlated Effects (CCE)} approach of Pesaran (2006).

{pstd}
Unlike tests that require explicit estimation of common factors (e.g., Bai-Ng
principal components), this command uses {bf:cross-section averages} as convenient
and robust proxies for the unobserved common factors. No pre-testing for the
number of factors is required.

{pstd}
The key result is the {bf:CADF_P panel statistic} — the cross-sectional mean of
individual unit-level CADF (Cross-section Augmented Dickey-Fuller) t-ratios
applied to the residuals of the pooled CCE regression:

{p 8 12 2}CADF_P = N^{-1} × Σᵢ t_{α̂_{i,0}}{p_end}

{pstd}
Under the null hypothesis of no cointegration, CADF_P is asymptotically normal.
Reject H0 if CADF_P < critical value (left-tail test).

{pstd}
The command faithfully translates the original GAUSS code {it:cadfcoin_multiple.src}
by Carrion-i-Silvestre (2021), ensuring numerical parity with the published results.


{marker background}{...}
{title:Background and Motivation}

{dlgtab:The Problem: Cross-Section Dependence in Panel Cointegration}

{pstd}
Early panel cointegration tests (Kao 1999, Pedroni 2000) assumed cross-section
independence — an assumption rarely met in economic panels. Cross-section dependence
arises from:

{p 8 12 2}• Common global shocks (oil prices, financial crises){p_end}
{p 8 12 2}• Market integration and globalization{p_end}
{p 8 12 2}• Spillover effects among regions/countries{p_end}

{pstd}
Ignoring cross-section dependence leads to severe size distortions in standard
panel cointegration tests.

{dlgtab:The CCE Solution}

{pstd}
The CCE approach (Pesaran 2006) augments individual cross-section regressions
with {bf:cross-sectional averages} ȳ_t and x̄_{j,t} of the dependent and independent
variables. These averages serve as proxies for the unobserved common factors:

{p 8 12 2}Ŷ_t ≈ F_t (as N → ∞){p_end}

{pstd}
This makes CCE-based procedures {bf:asymptotically equivalent to factor-based
procedures} (Pesaran 2007, Pesaran et al. 2013), without requiring the estimation
or identification of the number of factors.

{dlgtab:Link to Pesaran (2007) Panel Unit Root Test}

{pstd}
The CADF_P statistic in this command is {bf:asymptotically equivalent} to the CIPS
panel unit root statistic in Pesaran (2007) and the Pesaran et al. (2013) test
for multiple common factors. The key difference is that here the test is applied
to the {it:residuals} of the PCCE regression, not to the raw series.

{pstd}
This means {cmd:xtccecoint} can be seen as a CCE-augmented version of existing
panel unit root and cointegration tests.


{marker models}{...}
{title:Model Specifications}

{dlgtab:Model 0 — No Deterministics}

{pstd}No intercept, no trend. The DGP is:

{p 8 12 2}y_{i,t} = β'x_{i,t} + Λ_i F_t + ε_{i,t}{p_end}

{dlgtab:Model 1 — Constant (default for I(0) processes)}

{pstd}With individual-specific intercepts:

{p 8 12 2}y_{i,t} = α_i + β'x_{i,t} + Λ_i F_t + ε_{i,t}{p_end}

{pstd}Truncation constants: (d1, d2) = (6.19, 2.61).

{dlgtab:Model 2 — Constant + Linear Trend (default for trending series)}

{pstd}With individual-specific intercepts AND linear trends:

{p 8 12 2}y_{i,t} = α_i + δ_i t + β'x_{i,t} + Λ_i F_t + ε_{i,t}{p_end}

{pstd}Truncation constants: (d1, d2) = (6.42, 1.70).

{pstd}
{bf:Recommendation}: Use Model 2 for most macroeconomic panels (GDP, prices,
production functions). Use Model 1 for mean-stationary panels (ratios, rates).


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} specifies the deterministic component:

{p 12 16 2}{bf:0} = no deterministics{p_end}
{p 12 16 2}{bf:1} = constant (intercept only){p_end}
{p 12 16 2}{bf:2} = constant + linear trend. {bf:Default.}{p_end}

{phang}
{opt nfactors(#)} sets the number of common factors r. This controls how many
cross-section averages enter the CADF regression:

{p 12 16 2}{bf:r = 1}: Only ȳ_t enters (Pesaran 2007 equivalence). Use when one dominant factor.{p_end}
{p 12 16 2}{bf:r = k+1}: All k+1 averages enter (rank condition with equality). Conservative and recommended default for unknown structure.{p_end}
{p 12 16 2}Intermediate values: r CS averages of regressors are included.{p_end}

{phang}
{opt method(#)} controls how cross-section dependence is handled:

{p 12 16 2}{bf:0} = OLS per unit (no CSD adjustment). Use only for independent panels.{p_end}
{p 12 16 2}{bf:1} = CCE augmentation. {bf:Default.}{p_end}

{phang}
{opt option(#)} selects the CCE coefficient estimator:

{p 12 16 2}{bf:0} = Individual CCE: unit-by-unit OLS with CS augmentation{p_end}
{p 12 16 2}{bf:1} = Mean Group CCE (MGCCE): average of individual CCE estimates{p_end}
{p 12 16 2}{bf:2} = Pooled CCE (PCCE): pooled estimator. {bf:Default. Recommended.}{p_end}

{phang}
{opt plags(#)} sets the AR lag order p for the CADF regression. Following Pesaran
(2007), increasing p accounts for higher-order serial correlation in the
idiosyncratic component. Default is {bf:1}. Try values 0, 1, 2, 3, 4 to
assess robustness.

{phang}
{opt notruncate} disables truncation of individual t-ratios to the range
[-d1, d2]. Truncation (default ON) ensures the panel mean statistic has
finite moments even in small samples, following Pesaran (2007, p.277).

{phang}
{opt plot} produces 4 publication-quality diagnostic plots:

{p 12 16 2}(1) Individual CADF statistics: sorted dot chart by unit{p_end}
{p 12 16 2}(2) Cross-section averages (CCE factor proxies) time series{p_end}
{p 12 16 2}(3) Histogram of individual statistics vs. critical values{p_end}
{p 12 16 2}(4) Combined 2×2 dashboard{p_end}

{phang}
{opt saving(string)} saves all plots as PNG files with the given stem prefix.

{phang}
{opt noisily} shows detailed Mata computation output (unit-by-unit statistics).


{marker interpretation}{...}
{title:How to Interpret the Results}

{p 4 8 2}{bf:Step 1: Check the CADF_P statistic.}{p_end}

{p 8 12 2}
If CADF_P < CV (5%), reject H0: strong evidence of panel cointegration.{p_end}
{p 8 12 2}
If CADF_P > CV (10%), do not reject H0: no evidence of panel cointegration.{p_end}

{p 4 8 2}{bf:Step 2: Check robustness across lag specifications.}{p_end}

{p 8 12 2}
Re-run with different values of {opt plags()}: 0, 1, 2, 3. If the conclusion
is consistent, the result is robust. Divergent results suggest the lag order
matters and longer lags may be needed.{p_end}

{p 4 8 2}{bf:Step 3: Check individual statistics.}{p_end}

{p 8 12 2}
{cmd:matrix list e(cadf_ind)} shows unit-specific statistics. Panel rejection
of H0 does not imply all units are cointegrated — some may be spurious
while others are truly cointegrated.{p_end}

{p 4 8 2}{bf:Step 4: Compare r = 1 vs. r = k+1.}{p_end}

{p 8 12 2}
Re-run with {opt nfactors(1)} (r=1, inequality case) and compare with the
default (r=k+1, equality case). If both agree, the conclusion is robust to
uncertainty about the number of common factors.{p_end}

{p 4 8 2}{bf:Key note on the null hypothesis:}{p_end}

{p 8 12 2}
H0 is no cointegration. Failing to reject H0 is NOT evidence of cointegration —
it is simply a lack of evidence against poor integration. Rejection of H0
constitutes statistical evidence for cointegration.{p_end}

{dlgtab:Comparing with xtbreakcoint}

{pstd}
{cmd:xtccecoint} and {cmd:xtbreakcoint} test for panel cointegration from
complementary angles:

{p 8 12 2}
{bf:xtccecoint}: Time-series data or panel; accounts for cross-section dependence
via CCE; no structural breaks required.{p_end}
{p 8 12 2}
{bf:xtbreakcoint}: Purpose-built panel cointegration with structural breaks; requires
large panel (N > 5, T > 50).{p_end}


{marker critval}{...}
{title:Critical Values}

{pstd}
Critical values are tabulated from Monte Carlo simulations using 50,000
replications under a DGP with independent I(1) regressors and no cointegration,
following the procedure in Banerjee and Carrion-i-Silvestre (2017).

{pstd}
Tables are indexed by: model, k+1 (observables), r (common factors), p (AR lags),
T ∈ {30, 50, 70, 100, 200}, N ∈ {20, 30, 50, 70, 100, 200}.

{pstd}
For T and N values not in the grid, bilinear interpolation is applied.

{pstd}
{bf:Example (Model 2, r=1, k=1 [k+1=2], p=1):}

{p2colset 9 28 30 0}{...}
{p2col:T \ N}20{space 4}30{space 4}50{space 4}70{space 4}100{space 4}200{p_end}
{p2col:{hline 52}}{p_end}
{p2col:30 (5%)} -2.96  -2.91  -2.86  -2.84  -2.83  -2.81{p_end}
{p2col:50 (5%)} -2.85  -2.80  -2.75  -2.72  -2.71  -2.69{p_end}
{p2col:100 (5%)}-2.78  -2.72  -2.67  -2.65  -2.63  -2.61{p_end}
{p2col:200 (5%)}-2.75  -2.69  -2.64  -2.62  -2.60  -2.58{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: US House Prices (replication of Holly et al. 2010 / Section 5.1)}

{pstd}
49 US states, annual 1975–2003 (N=49, T=29). Testing cointegration between
log real house prices (lnhp) and log real per-capita disposable income (lninc).

{phang}{cmd:. * Setup: use real data or simulate}{p_end}
{phang}{cmd:. use xtccecoint_example.dta, clear}{p_end}
{phang}{cmd:. xtset state year}{p_end}

{phang}{cmd:. * Run with one common factor (as in Holly et al. 2010)}{p_end}
{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(1) plags(1)}{p_end}

{pstd}
{bf:Expected}: CADF_P ≈ -2.56 for p=1. Reject H0 at 5% → evidence of cointegration.

{phang}{cmd:. * Robustness across lag orders}{p_end}
{phang}{cmd:. forvalues p = 0/4 {c -(}}{p_end}
{phang}{cmd:. {space 4}xtccecoint lnhp lninc, model(1) nfactors(1) plags(`p') notable}{p_end}
{phang}{cmd:. {space 4}di "p=`p': CADF_P = " e(cadfp)}{p_end}
{phang}{cmd:. {c )-}}{p_end}

{pstd}
{bf:Example 2: OECD Production Function (Section 5.2)}

{pstd}
19 OECD countries, annual 1951–2007 (N=19, T=57). Production function:
log GDP = α_i + β₁ log(labor) + β₂ log(capital) + u_it.

{phang}{cmd:. xtccecoint lngdp lnlab lncap, model(2) nfactors(3) plags(2)}{p_end}
{phang}{cmd:. * nfactors(3) = k+1 = 3 regressors + 1 (rank condition with equality)}{p_end}

{pstd}
{bf:Example 3: With diagnostic plots}

{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(1) plags(1) plot saving(hp_test)}{p_end}

{pstd}
{bf:Example 4: Compare r=1 (inequality) vs. r=k+1 (equality)}

{phang}{cmd:. * Conservative: assume rank condition met with equality (default)}{p_end}
{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(2) plags(1)}{p_end}
{phang}{cmd:. di "Equality case: CADF_P = " e(cadfp)}{p_end}
{phang}{cmd:. * Liberal: assume only one common factor}{p_end}
{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(1) plags(1)}{p_end}
{phang}{cmd:. di "Inequality case: CADF_P = " e(cadfp)}{p_end}

{pstd}
{bf:Example 5: Accessing stored results}

{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(1) plags(1)}{p_end}
{phang}{cmd:. ereturn list                  // all stored scalars and matrices}{p_end}
{phang}{cmd:. display e(cadfp)             // panel CADF_P statistic}{p_end}
{phang}{cmd:. display e(cv5)               // 5% critical value}{p_end}
{phang}{cmd:. matrix list e(cadf_ind)      // individual unit statistics}{p_end}
{phang}{cmd:. matrix list e(b)             // PCCE slope estimates}{p_end}

{pstd}
{bf:Example 6: Using with xtnumfac for automatic factor selection}

{phang}{cmd:. xtnumfac lnhp lninc              // estimate number of factors}{p_end}
{phang}{cmd:. local rhat = r(factors)}{p_end}
{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(`rhat') plags(1)}{p_end}

{pstd}
{bf:Example 7: Comparison with xtbreakcoint (complementary test)}

{phang}{cmd:. * CCE-based test (this command)}{p_end}
{phang}{cmd:. xtccecoint lnhp lninc, model(1) nfactors(1) plags(2)}{p_end}
{phang}{cmd:. * Factor-based test with breaks}{p_end}
{phang}{cmd:. xtbreakcoint lnhp lninc, model(2)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtccecoint} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Scalars}{p_end}
{synopt:{cmd:e(cadfp)}}Panel CADF_P statistic (cross-sectional mean of individual t-ratios){p_end}
{synopt:{cmd:e(cv5)}}5% asymptotic critical value{p_end}
{synopt:{cmd:e(cv10)}}10% asymptotic critical value{p_end}
{synopt:{cmd:e(N)}}number of cross-section units{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(k)}}number of stochastic regressors{p_end}
{synopt:{cmd:e(nfactors)}}number of common factors used{p_end}
{synopt:{cmd:e(plags)}}AR lag order{p_end}
{synopt:{cmd:e(model)}}model type (0, 1, or 2){p_end}
{synopt:{cmd:e(method)}}CSD method (0=OLS, 1=CCE){p_end}
{synopt:{cmd:e(opttype)}}estimator type (0=CCEI, 1=MG, 2=PCCE){p_end}
{synopt:{cmd:e(truncated)}}1 if truncation applied, 0 otherwise{p_end}

{p2col 5 22 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}1 × k vector of PCCE/CCE slope estimates{p_end}
{synopt:{cmd:e(V)}}k × k variance-covariance matrix (placeholder — set to zero; standard
errors for the cointegrating vector are not provided){p_end}
{synopt:{cmd:e(cadf_ind)}}1 × N vector of individual CADF t-ratios{p_end}

{p2col 5 22 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtccecoint}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvars)}}independent variable names{p_end}
{synopt:{cmd:e(panelvar)}}panel ID variable{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(estimator)}}estimator description{p_end}
{synopt:{cmd:e(modtype)}}model specification description{p_end}
{synopt:{cmd:e(papers)}}citation{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}


{title:Acknowledgements}

{pstd}
This command is a faithful Stata/Mata translation of the original GAUSS code
{it:cadfcoin_multiple.src} by Josep Lluís Carrion-i-Silvestre (University of
Barcelona, August 21st, 2021), provided as supplementary material to:

{pstd}
Banerjee, A. & Carrion-i-Silvestre, J.L. (2017). Testing for Panel Cointegration
Using Common Correlated Effects Estimators. {it:Journal of Time Series Analysis},
DOI: 10.1111/jtsa.12234.

{pstd}
The CCE approach is due to Pesaran (2006). The CIPS/CADF panel unit root test is 
from Pesaran (2007). Critical values simulation methodology follows Pesaran et al. (2013).
The truncation thresholds follow Pesaran (2007, p.277).

{pstd}
{bf:Related commands by the same author:}
{helpb xtbreakcoint} (Banerjee & CiS 2015), {helpb cupfm} (Bai, Kao & Ng 2009),
{helpb cobreakcoint} (Carrion-i-Silvestre & Kim 2019).


{title:References}

{pstd}
Banerjee, A. & Carrion-i-Silvestre, J.L. (2017). Testing for Panel Cointegration Using
Common Correlated Effects Estimators. {it:J. Time Series Anal.}, DOI: 10.1111/jtsa.12234.

{pstd}
Holly, S., Pesaran, M.H. & Yamagata, T. (2010). A spatio-temporal model of house prices
in the USA. {it:J. Econometrics}, 158, 160–173.

{pstd}
Pesaran, M.H. (2006). Estimation and inference in large heterogeneous panels with a
multifactor error structure. {it:Econometrica}, 74, 967–1012.

{pstd}
Pesaran, M.H. (2007). A simple panel unit root test in the presence of cross-section
dependence. {it:J. Appl. Econometrics}, 22, 265–312.

{pstd}
Pesaran, M.H., Ullah, A. & Yamagata, T. (2013). A bias-adjusted LM test of error
cross-section independence. {it:Econometrics J.}, 11, 105–127.


{title:Also see}

{psee}
{space 2}Help: {helpb xtbreakcoint}, {helpb cupfm}, {helpb cobreakcoint},
{helpb xtdcce2}, {helpb xtcce}, {helpb xtnumfac}, {helpb xtcd2}
{p_end}
