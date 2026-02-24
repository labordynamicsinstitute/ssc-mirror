{smcl}
{* *! caustests v1.1.0  22feb2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "[TS] vargranger" "help vargranger"}{...}
{viewerjumpto "Syntax" "caustests##syntax"}{...}
{viewerjumpto "Description" "caustests##description"}{...}
{viewerjumpto "Options" "caustests##options"}{...}
{viewerjumpto "Tests" "caustests##tests"}{...}
{viewerjumpto "Examples" "caustests##examples"}{...}
{viewerjumpto "Stored results" "caustests##stored"}{...}
{viewerjumpto "References" "caustests##references"}{...}
{viewerjumpto "Author" "caustests##author"}{...}
{title:Title}

{phang}
{bf:caustests} {hline 2} Granger Causality Tests: Toda-Yamamoto, Fourier, and Quantile Variants

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:caustests}
{varlist} ({it:min}=2, time series)
[{cmd:,}
{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt test(#)}}test type (1–7); see {help caustests##tests:Tests}{p_end}

{syntab:Optional}
{synopt:{opt pmax(#)}}maximum lag order; default {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}information criterion: 1=AIC (default), 2=SBC{p_end}
{synopt:{opt nboot(#)}}bootstrap replications; default {cmd:nboot(1000)}{p_end}
{synopt:{opt kmax(#)}}maximum Fourier frequency; default {cmd:kmax(3)}{p_end}
{synopt:{opt dmax(#)}}integration order for TY augmentation; default auto{p_end}
{synopt:{opt quantiles(numlist)}}quantiles for tests 6–7; default {cmd:0.1(0.1)0.9}{p_end}
{synopt:{opt graph}}produce causality graphs (tests 6 and 7 only){p_end}
{synopt:{opt noh:eader}}suppress header output{p_end}
{synopt:{opt scheme(name)}}graph scheme; default {cmd:s1color}{p_end}
{synoptline}

{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:caustests} implements seven Granger causality tests for multivariate time
series data. Tests 1–5 extend the classical Granger (1969) framework using
the Toda-Yamamoto (1995) lag-augmentation approach and/or Fourier
approximations to capture smooth structural breaks of unknown form.
Tests 6 and 7 extend the analysis to the full conditional distribution
via quantile regression.

{pstd}
All tests report bootstrap p-values from residual resampling under H0.
Tests 1–5 also report asymptotic chi-squared p-values.
Optimal lag length and Fourier frequency (where
applicable) are selected by minimizing AIC or SBC.

{pstd}
For a system with {it:k} variables, {cmd:caustests} tests all {it:k}({it:k}-1)
directional causality hypotheses simultaneously.

{marker tests}{...}
{title:Tests}

{pstd}
{ul:Summary — estimation in levels vs. first differences:}{break}
  Tests 1, 3, 5, 6, 7: estimated in {bf:levels} (d_max >= 1, TY augmentation){break}
  Tests 2, 4:           estimated in {bf:first differences} (d_max = 0)

{phang2}{bf:test(1)} — {it:Toda-Yamamoto (1995) Causality Test}{break}
Estimates VAR({it:p}+{it:d_max}) in {ul:levels}. The Wald test is applied to the
first {it:p} lags of each candidate causal variable, ignoring the extra
{it:d_max} augmented lags. Valid regardless of the integration or
cointegration properties of the series. Output: Wald, AIC/SBC optimal lag,
asymptotic and bootstrap p-values.

{phang2}{bf:test(2)} — {it:Single Fourier-Frequency Granger Causality Test} (Enders & Jones, 2016){break}
Estimates VAR in {ul:first differences} ({it:d_max}=0) with the intercept
modeled as a single Fourier frequency:
{it:α}({it:t}) = {it:α₀}+{it:γ}₁sin(2π{it:kt/T})+{it:γ}₂cos(2π{it:kt/T}).
Optimal frequency {it:k*}∈{1,...,kmax} selected jointly with lag {it:p} by AIC/SBC.

{phang2}{bf:test(3)} — {it:Single Fourier-Frequency Toda-Yamamoto Test} (Nazlioglu et al., 2016){break}
Combines test(2) Fourier intercept with the TY lag augmentation in
{ul:levels} ({it:d_max}=1). Primary innovation: robust to non-stationarity
AND smooth structural breaks simultaneously.

{phang2}{bf:test(4)} — {it:Cumulative Fourier-Frequency Granger Causality Test} (Enders & Jones, 2019){break}
VAR in {ul:first differences}. Intercept modeled with {ul:cumulative} Fourier
terms up to frequency {it:k*}:
{it:α}({it:t}) = {it:α₀}+Σ_{j=1}^{k*}[{it:γ}₁ⱼsin(2π{it:jt/T})+{it:γ}₂ⱼcos(2π{it:jt/T})].
Better approximation for multiple or complex structural changes.

{phang2}{bf:test(5)} — {it:Cumulative Fourier-Frequency Toda-Yamamoto Test} (Nazlioglu et al., 2019){break}
Combines test(4) cumulative Fourier approximation with TY augmentation in
{ul:levels} ({it:d_max}=1). Most general Fourier-TY test.

{phang2}{bf:test(6)} — {it:Toda-Yamamoto Causality Test in Quantiles} (Cai et al., 2023){break}
Quantile extension of the TY test. Estimates:
{it:Q}_{y}(τ|·) = {it:c}(τ) + Σ_{i=1}^{p+1}θ_i(τ){it:y}_{t-i} + Σ_{j=1}^{p+1}ρ_j(τ){it:x}_{t-j}
Then tests H₀: ρ₁(τ)=…=ρ_p(τ)=0. Detects causality at specific quantiles
of the conditional distribution (e.g., lower/upper tails), revealing
heterogeneous causal relationships invisible to mean-based tests.
The quantile regression Wald statistic is displayed; bootstrap p-values
are computed via quantile regression residual resampling under H0.

{phang2}{bf:test(7)} — {it:Bootstrap Fourier Granger Causality in Quantiles (BFGC-Q)} (Cheng et al., 2021){break}
Most comprehensive test. Extends test(6) by adding Fourier terms:
{it:Q}_{y}(τ|·) = γ₀(τ)+γ₁(τ)sin(2π{it:k*t/T})+γ₂(τ)cos(2π{it:k*t/T})
               + Σ_{i=1}^{p*+1}θ_i(τ){it:y}_{t-i} + Σ_{j=1}^{p*+1}ρ_j(τ){it:x}_{t-j}
H₀: ρ₁(τ)=…=ρ_{p*}(τ)=0. Optimal (k*,p*) selected jointly.
Robust to: non-stationarity (TY augmentation), structural breaks (Fourier),
and distributional heterogeneity (quantile regression).
The quantile regression Wald statistic is displayed; bootstrap p-values
are computed via quantile regression residual resampling under H0.

{marker options}{...}
{title:Options}

{phang}{opt pmax(#)} specifies the maximum number of lags to consider for AIC/SBC selection. Default is 8. The optimal lag is selected by minimizing the chosen information criterion.

{phang}{opt ic(#)} selects the information criterion for optimal lag and frequency selection.
1 = Akaike Information Criterion (AIC, default).
2 = Schwarz-Bayesian Criterion (SBC).

{phang}{opt nboot(#)} sets the number of bootstrap replications used to compute bootstrap p-values. Default is 1000. Use at least 999 for publication.

{phang}{opt kmax(#)} sets the maximum Fourier frequency searched (tests 2–5, 7). For each frequency {it:k}∈{1,...,kmax}, the implied number of Fourier components is 2 for single (tests 2,3) and 2{it:k} for cumulative (tests 4,5,7). Default is 3.

{phang}{opt dmax(#)} overrides the automatic setting of the maximum integration order for TY augmentation. By default: {it:d_max}=0 for tests 2,4 (Granger in differences) and {it:d_max}=1 for tests 1,3,5,6,7 (TY in levels).

{phang}{opt quantiles(numlist)} specifies the quantiles at which to evaluate causality for tests 6 and 7. Each value must be strictly between 0 and 1. Default is {cmd:0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9}.

{phang}{opt graph} produces two combined graphs for tests 6 and 7: (1) Wald statistics across quantiles for each causal direction, and (2) bootstrap p-values across quantiles with significance threshold lines.

{phang}{opt noheader} suppresses the descriptive test header.

{phang}{opt scheme(name)} specifies the graph scheme for figures (default: {cmd:s1color}).

{marker examples}{...}
{title:Examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Toda-Yamamoto test:{p_end}
{phang2}{cmd:. caustests dln_inv dln_inc dln_consump, test(1) pmax(4)}{p_end}

{pstd}Single Fourier Toda-Yamamoto (Nazlioglu et al. 2016):{p_end}
{phang2}{cmd:. caustests dln_inv dln_inc, test(3) pmax(4) kmax(3) nboot(1000)}{p_end}

{pstd}Cumulative Fourier Toda-Yamamoto (Nazlioglu et al. 2019):{p_end}
{phang2}{cmd:. caustests dln_inv dln_inc dln_consump, test(5) pmax(4) kmax(3)}{p_end}

{pstd}Quantile Toda-Yamamoto (Cai et al. 2023):{p_end}
{phang2}{cmd:. caustests dln_inv dln_inc, test(6) pmax(4) }{break}
    {cmd:quantiles(0.10 0.25 0.50 0.75 0.90) nboot(1000) graph}{p_end}

{pstd}BFGC-Q (Cheng et al. 2021):{p_end}
{phang2}{cmd:. caustests dln_inv dln_inc dln_consump, test(7) pmax(4) kmax(3)}{break}
    {cmd:quantiles(0.10 0.25 0.50 0.75 0.90) nboot(1000) graph}{p_end}

{pstd}Using SBC instead of AIC:{p_end}
{phang2}{cmd:. caustests y1 y2 y3, test(3) pmax(6) ic(2) nboot(2000)}{p_end}

{marker stored}{...}
{title:Stored Results}

{pstd}
{cmd:caustests} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 18 2: Scalars:}{p_end}
{synopt:{cmd:e(test)}}test number (1–7){p_end}

{p2col 5 18 18 2: Tests 1–5 (OLS):}{p_end}
{synopt:{cmd:e(wald)}}Wald statistics ({it:k}({it:k}-1)×1){p_end}
{synopt:{cmd:e(pval_a)}}asymptotic chi-squared p-values{p_end}
{synopt:{cmd:e(pval_b)}}bootstrap p-values{p_end}
{synopt:{cmd:e(lags)}}optimal lag orders{p_end}
{synopt:{cmd:e(freq)}}optimal Fourier frequencies (0 for tests 1, 6){p_end}

{p2col 5 18 18 2: Tests 6–7 (Quantile):}{p_end}
{synopt:{cmd:e(wald_q)}}Wald statistics ({it:dirs}×{it:quantiles}){p_end}
{synopt:{cmd:e(pval_bq)}}bootstrap p-values ({it:dirs}×{it:quantiles}){p_end}
{synopt:{cmd:e(lags_q)}}optimal lag orders ({it:dirs}×1){p_end}
{synopt:{cmd:e(freq_q)}}optimal Fourier frequencies ({it:dirs}×1, test 7 only){p_end}
{p2colreset}{...}

{marker references}{...}
{title:References}

{phang}
Granger, C.W.J. (1969). Investigating causal relations by econometric models
and cross-spectral methods. {it:Econometrica} 37: 424–438.

{phang}
Toda, H.Y., Yamamoto, T. (1995). Statistical inference in vector autoregressions
with possibly integrated processes. {it:Journal of Econometrics} 66: 225–250.

{phang}
Enders, W., Jones, P. (2016). Grain prices, oil prices, and multiple smooth
breaks in a VAR. {it:Studies in Nonlinear Dynamics and Econometrics}.
doi:10.1515/snde-2014-0101.

{phang}
Nazlioglu, S., Gormus, A., Soytas, U. (2016). Oil prices and real estate
investment trusts: Gradual-shift causality and volatility transmission analysis.
{it:Energy Economics} 60: 168–175.

{phang}
Nazlioglu, S., Soytas, U., Gormus, A. (2019). Oil prices and monetary policy
in emerging markets: Structural shifts in causal linkages.
{it:Emerging Markets Finance and Trade} 55: 105–117.

{phang}
Cai, Y., Chang, H.W., Xiang, F., Chang, T. (2023). Can precious metals hedge
the risks of Sino-US political relation? Evidence from Toda-Yamamoto causality
test in quantiles. {it:Finance Research Letters} 58: 104327.

{phang}
Cheng, K., Hsueh, H.P., Ranjbar, O., Wang, M.C., Chang, T. (2021).
Urbanization, coal consumption and CO2 emissions nexus in China using bootstrap
Fourier Granger causality test in quantiles.
{it:Letters in Spatial and Resource Sciences} 14: 31–49.

{phang}
Efron, B. (1979). Bootstrap methods: Another look at the jackknife.
{it:Annals of Statistics} 7: 1–26.

{marker author}{...}
{title:Author}

{phang}
Dr Merwan Roudane{break}
E-mail: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{phang}
The author makes no performance guarantees. For bug reports or suggestions, please send an e-mail to the address above.

{title:Also see}

{psee}
{helpb var}, {helpb vargranger}, {helpb qreg}, {helpb varsoc}
{p_end}
