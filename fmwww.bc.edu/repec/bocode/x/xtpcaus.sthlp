{smcl}
{* *! version 1.0.0  08mar2026}{...}
{viewerjumpto "Syntax" "xtpcaus##syntax"}{...}
{viewerjumpto "Description" "xtpcaus##description"}{...}
{viewerjumpto "Options" "xtpcaus##options"}{...}
{viewerjumpto "Methodology" "xtpcaus##methodology"}{...}
{viewerjumpto "Examples" "xtpcaus##examples"}{...}
{viewerjumpto "Stored results" "xtpcaus##results"}{...}
{viewerjumpto "Remarks" "xtpcaus##remarks"}{...}
{viewerjumpto "References" "xtpcaus##references"}{...}
{viewerjumpto "Author" "xtpcaus##author"}{...}

{title:Title}

{phang}
{bf:xtpcaus} {hline 2} Panel Causality Tests: Panel Fourier Toda-Yamamoto (PFTY)
    and Panel Quantile Causality (PQC)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtpcaus} {depvar} {indepvar}
{ifin}{cmd:,}
{opt test(pfty|pqc)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt test(string)}}test type: {bf:pfty} for Panel Fourier Toda-Yamamoto
    or {bf:pqc} for Panel Quantile Causality{p_end}

{syntab:Common options}
{synopt:{opt pmax(#)}}maximum lag order for AIC/SBC selection; default is {bf:4}{p_end}
{synopt:{opt dmax(#)}}maximum integration order (extra lags for Toda-Yamamoto augmentation); default is {bf:1}{p_end}
{synopt:{opt nboot(#)}}number of bootstrap replications; minimum 99; default is {bf:1000}{p_end}
{synopt:{opt seed(#)}}random-number seed for reproducible bootstrap results{p_end}
{synopt:{opt nog:raph}}suppress graphical output{p_end}
{synopt:{opt not:able}}suppress tabular output{p_end}
{synopt:{opt level(#)}}confidence level for significance; default is {bf:95}{p_end}
{synopt:{opt scheme(string)}}Stata graph scheme; default is {bf:s1color}{p_end}

{syntab:PFTY-specific options}
{synopt:{opt kmax(#)}}maximum Fourier frequency to search over; default is {bf:3}{p_end}
{synopt:{opt ic(aic|sbc)}}information criterion for joint lag and frequency selection; default is {bf:aic}{p_end}

{syntab:PQC-specific options}
{synopt:{opt q:uantiles(numlist)}}quantile grid for testing; values must be strictly between 0 and 1;
    default is {bf:0.05 0.10 0.25 0.50 0.75 0.90 0.95}{p_end}
{synoptline}

{pstd}
{cmd:xtset} {it:panelvar} {it:timevar} must be specified before using {cmd:xtpcaus}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpcaus} implements two panel Granger causality tests for {bf:strongly balanced} panel data.
The command tests whether {it:indepvar} Granger-causes {it:depvar}, with both individual-level
and panel-level test statistics. For each test, bootstrap p-values account for
cross-sectional dependence among panel units.

{pstd}
{bf:Test 1: Panel Fourier Toda-Yamamoto (PFTY)}

{pstd}
Following Yilanci and Gorus (2020), this test augments the Toda-Yamamoto (1995) VAR with
Fourier trigonometric terms to capture unknown structural breaks of unknown form, number,
and date. The procedure is:

{p 8 12 2}(i) For each panel unit i, estimate a VAR(k_i+d_max) augmented with Fourier terms
sin(2*pi*f*t/T) and cos(2*pi*f*t/T), where k_i and f are jointly selected by AIC/SBC.{p_end}

{p 8 12 2}(ii) Compute the individual Wald statistic W_i testing the null that the first k_i
lagged coefficients of {it:indepvar} are jointly zero (Granger non-causality).{p_end}

{p 8 12 2}(iii) Obtain bootstrap p-values p*_i for each unit using the residual-based
sieve bootstrap under the null (Nazlioglu et al. 2016).{p_end}

{p 8 12 2}(iv) Compute the Fisher panel statistic PFTY = -2*sum(ln(p*_i)) ~ Chi2(2N)
(Emirmahmutoglu and Kose 2011).{p_end}

{p 8 12 2}(v) Report Dumitrescu-Hurlin Z-bar and Z-bar-tilde statistics for comparison.{p_end}

{pstd}
{bf:Test 2: Panel Quantile Causality (PQC)}

{pstd}
Following Wang and Nguyen (2022) and Chuang, Kuan, and Lin (2009), this test examines Granger
causality across the conditional distribution using quantile regression. The procedure is:

{p 8 12 2}(i) Estimate a panel quantile VAR with country-specific intercepts (fixed effects):
Q(y_it | tau) = b_0i(tau) + sum_j b_1j(tau)*y_{i,t-j} + sum_j b_2j(tau)*x_{i,t-j}{p_end}

{p 8 12 2}(ii) For each quantile tau, compute the Wald statistic testing H0: b_2(tau) = 0.{p_end}

{p 8 12 2}(iii) Obtain bootstrap p-values under the null using the restricted quantile regression.{p_end}

{p 8 12 2}(iv) Compute the Sup-Wald = max(W(tau)) across all quantiles and compare against
critical values from Chuang et al. (2009) Table 1.{p_end}

{p 8 12 2}(v) Both directions (x=>y and y=>x) are tested simultaneously.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt test(string)} specifies the test to perform. {bf:pfty} runs the Panel Fourier
Toda-Yamamoto test. {bf:pqc} runs the Panel Quantile Causality test.

{dlgtab:Common options}

{phang}
{opt pmax(#)} specifies the maximum lag order to search over when selecting the optimal
lag via AIC or SBC. Higher values allow longer lag structures but reduce degrees of freedom.
Default is 4. For short panels (T<20), consider pmax(2) or pmax(3).

{phang}
{opt dmax(#)} specifies the maximum integration order of the variables. Following
Toda and Yamamoto (1995), the VAR is estimated at order k+dmax to ensure valid
chi-square asymptotics regardless of integration/cointegration properties.
Set dmax=1 for I(1) variables, dmax=2 for potentially I(2) variables. Default is 1.

{phang}
{opt nboot(#)} specifies the number of bootstrap replications. Higher values give more
precise p-values. Minimum is 99. Default is 1000.
For quick tests use nboot(199-499); for publication use nboot(999-2000).

{phang}
{opt seed(#)} sets the random-number seed for bootstrap resampling, ensuring
reproducible results.

{phang}
{opt nograph} suppresses all graphical output. Tables are still displayed.

{phang}
{opt notable} suppresses tabular output. Graphs are still displayed.

{phang}
{opt level(#)} sets the confidence level for significance stars. Default is 95.

{phang}
{opt scheme(string)} specifies the Stata graph scheme. Default is {bf:s1color}.
Other common choices: {bf:s2color}, {bf:s1mono}, {bf:economist}.

{dlgtab:PFTY-specific options}

{phang}
{opt kmax(#)} specifies the maximum Fourier frequency to consider.
Enders and Lee (2012) recommend kmax=3 for most applications, since low-frequency
components capture the most common structural break patterns. Default is 3.

{phang}
{opt ic(aic|sbc)} specifies the information criterion used to jointly select both
the optimal lag order k and the optimal Fourier frequency f for each panel unit.
{bf:aic} (Akaike) tends to select more parameters; {bf:sbc} (Schwarz/BIC) is more
parsimonious. Default is {bf:aic}. {bf:bic} is accepted as a synonym for {bf:sbc}.

{dlgtab:PQC-specific options}

{phang}
{opt quantiles(numlist)} specifies the quantiles at which to test for causality.
All values must be strictly between 0 and 1. The Sup-Wald statistic is taken over
this grid. Default is {bf:0.05 0.10 0.25 0.50 0.75 0.90 0.95}. Denser grids
improve the power of the Sup-Wald test but increase computation time.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:PFTY — Panel Fourier Toda-Yamamoto}

{pstd}
The individual augmented VAR for unit i (Yilanci and Gorus 2020, Eq. 3):

{p 8 8 2}
y_it = a_i + sum_{j=1}^{k_i+d_max} b_1ij*y_{i,t-j} + sum_{j=1}^{k_i+d_max} b_2ij*x_{i,t-j}
+ g1_i*sin(2*pi*f_i*t/T) + g2_i*cos(2*pi*f_i*t/T) + e_it

{pstd}
The Wald test statistic W_i tests H0: b_21=b_22=...=b_{2,k_i}=0 (the first k_i
lags of x, excluding the d_max augmentation lags).

{pstd}
The PFTY panel statistic (Yilanci and Gorus 2020, Eq. 5):

{p 8 8 2}
PFTY = -2 * sum_{i=1}^{N} ln(p*_i) ~ Chi2(2N)

{pstd}
where p*_i are individual bootstrap p-values.

{pstd}
{bf:PQC — Panel Quantile Causality}

{pstd}
The panel quantile VAR (Wang and Nguyen 2022, Eq. 2-4):

{p 8 8 2}
Q_{y_it}(tau) = b_{0i}(tau) + sum_{j=1}^{p} b_{1j}(tau)*y_{i,t-j}
+ sum_{j=1}^{p} b_{2j}(tau)*x_{i,t-j}

{pstd}
where b_{0i}(tau) are country-specific intercepts (panel fixed effects in quantile
space). The Wald test at each quantile tau tests H0: b_2(tau)=0.

{pstd}
The Sup-Wald statistic (Chuang et al. 2009, Eq. 7):

{p 8 8 2}
Sup-Wald = max_{tau in T} W(tau)

{pstd}
where T = [0.05, 0.95]. Critical values from Chuang et al. (2009) Table 1.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}
{bf:Example 1: PFTY test — Does market value cause investment?}

{phang2}{cmd:. xtpcaus invest mvalue, test(pfty) pmax(2) kmax(3) dmax(1) nboot(499) seed(12345)}{p_end}

{pstd}
{bf:Example 2: PFTY reverse — Does investment cause market value?}

{phang2}{cmd:. xtpcaus mvalue invest, test(pfty) pmax(2) kmax(3) dmax(1) nboot(499) seed(12345)}{p_end}

{pstd}
{bf:Example 3: PFTY with SBC criterion and dmax=2}

{phang2}{cmd:. xtpcaus invest mvalue, test(pfty) pmax(3) kmax(3) dmax(2) nboot(499) ic(sbc) nograph}{p_end}

{pstd}
{bf:Example 4: PQC test — Full quantile grid}

{phang2}{cmd:. xtpcaus invest mvalue, test(pqc) pmax(2) nboot(499) quantiles(0.05 0.10 0.25 0.50 0.75 0.90 0.95) seed(54321)}{p_end}

{pstd}
{bf:Example 5: PQC test — Focus on tails}

{phang2}{cmd:. xtpcaus invest mvalue, test(pqc) pmax(2) nboot(499) quantiles(0.10 0.25 0.50 0.75 0.90)}{p_end}

{pstd}
{bf:Example 6: PQC with dense grid (9 quantiles)}

{phang2}{cmd:. xtpcaus invest mvalue, test(pqc) pmax(2) nboot(299) quantiles(0.05 0.10 0.20 0.30 0.50 0.70 0.80 0.90 0.95)}{p_end}

{pstd}
{bf:Example 7: Accessing stored results after PQC}

{phang2}{cmd:. mat list e(wald_xy)}{p_end}
{phang2}{cmd:. mat list e(coef_xy)}{p_end}
{phang2}{cmd:. di "Sup-Wald(x=>y) = " e(supwald_xy)}{p_end}
{phang2}{cmd:. di "5% critical value = " e(cv_05)}{p_end}

{pstd}
{bf:Example 8: Suppress output}

{phang2}{cmd:. xtpcaus invest mvalue, test(pfty) nograph notable}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
Both tests store the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}xtpcaus{p_end}
{synopt:{cmd:e(test)}}pfty or pqc{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvar)}}independent variable name{p_end}
{synopt:{cmd:e(panelvar)}}panel variable name{p_end}
{synopt:{cmd:e(timevar)}}time variable name{p_end}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_panels)}}number of panel units{p_end}
{synopt:{cmd:e(T_periods)}}number of time periods{p_end}
{synopt:{cmd:e(nboot)}}number of bootstrap replications{p_end}

{pstd}
{bf:PFTY-specific stored results:}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(fisher)}}Fisher panel test statistic = -2*sum(ln(p*_i)){p_end}
{synopt:{cmd:e(fisher_df)}}degrees of freedom = 2*N{p_end}
{synopt:{cmd:e(fisher_pv)}}Fisher p-value{p_end}
{synopt:{cmd:e(wbar)}}W-bar (average Wald statistic across panels){p_end}
{synopt:{cmd:e(zbar)}}Z-bar statistic (Dumitrescu-Hurlin standardized){p_end}
{synopt:{cmd:e(zbar_pv)}}Z-bar two-sided p-value{p_end}
{synopt:{cmd:e(zbart)}}Z-bar tilde (small-sample corrected){p_end}
{synopt:{cmd:e(zbart_pv)}}Z-bar tilde p-value{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(wald)}}individual Wald statistics (N x 1){p_end}
{synopt:{cmd:e(freq)}}optimal Fourier frequencies (N x 1){p_end}
{synopt:{cmd:e(pval_a)}}asymptotic p-values (N x 1){p_end}
{synopt:{cmd:e(pval_b)}}bootstrap p-values (N x 1){p_end}
{synopt:{cmd:e(lags)}}selected lag orders k_i (N x 1){p_end}

{pstd}
{bf:PQC-specific stored results:}

{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(supwald_xy)}}Sup-Wald statistic for x => y{p_end}
{synopt:{cmd:e(supwald_yx)}}Sup-Wald statistic for y => x{p_end}
{synopt:{cmd:e(cv_01)}}Sup-Wald 1% critical value (Chuang et al. 2009){p_end}
{synopt:{cmd:e(cv_05)}}Sup-Wald 5% critical value{p_end}
{synopt:{cmd:e(cv_10)}}Sup-Wald 10% critical value{p_end}
{synopt:{cmd:e(p_opt)}}selected optimal lag order{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(wald_xy)}}Wald statistics per quantile, x => y (1 x Q){p_end}
{synopt:{cmd:e(coef_xy)}}sum of cause coefficients per quantile, x => y (1 x Q){p_end}
{synopt:{cmd:e(pval_xy)}}bootstrap p-values per quantile, x => y (1 x Q){p_end}
{synopt:{cmd:e(wald_yx)}}Wald statistics per quantile, y => x (1 x Q){p_end}
{synopt:{cmd:e(coef_yx)}}sum of cause coefficients per quantile, y => x (1 x Q){p_end}
{synopt:{cmd:e(pval_yx)}}bootstrap p-values per quantile, y => x (1 x Q){p_end}


{marker remarks}{...}
{title:Remarks and important notes}

{pstd}
{bf:Requirements}

{p 8 12 2}1. Stata 14 or later.{p_end}
{p 8 12 2}2. Panel data must be declared with {cmd:xtset} {it:panelvar} {it:timevar}.{p_end}
{p 8 12 2}3. The panel must be {bf:strongly balanced} (no gaps, no missing values).{p_end}
{p 8 12 2}4. At least N >= 2 panel units and T >= 10 time periods.{p_end}
{p 8 12 2}5. Requires {cmd:qreg} for the PQC test (built into Stata).{p_end}

{pstd}
{bf:Warnings}

{p 8 12 2}1. {bf:Computation time.} Bootstrap resampling is computationally intensive.
For PFTY: time ~ N * nboot * (pmax * kmax) regressions.
For PQC: time ~ nboot * Q * 2 quantile regressions (Q = number of quantiles).
Use nboot(199-499) for exploration and nboot(999-2000) for final results.{p_end}

{p 8 12 2}2. {bf:Short panels.} With T < 15, limit pmax to 2 and dmax to 1 to preserve
degrees of freedom. The Z-bar-tilde correction requires T > 2*K + 5.{p_end}

{p 8 12 2}3. {bf:Extreme quantiles.} PQC estimates at very extreme quantiles (< 0.05 or > 0.95)
may be unreliable with small N*T. The Sup-Wald critical values from Chuang et al. (2009)
assume the quantile range [0.05, 0.95].{p_end}

{p 8 12 2}4. {bf:Large panels.} With very large N, the Fisher statistic may reject too
readily due to power accumulation. Consider the individual bootstrap p-values and
the Sup-Wald test for more nuanced inference.{p_end}

{pstd}
{bf:Notes on interpretation}

{p 8 12 2}1. {bf:PFTY significance stars} are based on individual {it:bootstrap} p-values,
which are more reliable than asymptotic p-values in the presence of cross-sectional
dependence.{p_end}

{p 8 12 2}2. {bf:PFTY Fisher statistic.} Reject the null of panel-level non-causality
if PFTY > Chi2(2N) at the chosen significance level.{p_end}

{p 8 12 2}3. {bf:PQC coefficient direction.} The sign (+/-) in the PQC table indicates
whether the causal effect at that quantile is positive or negative. This reveals
asymmetric effects (e.g., causality only in the tails).{p_end}

{p 8 12 2}4. {bf:PQC Sup-Wald.} Compare the Sup-Wald statistic against the critical
values reported from Chuang et al. (2009). If Sup-Wald > cv_05, reject the null
of non-causality at the 5% level across all quantiles simultaneously.{p_end}

{p 8 12 2}5. {bf:Bidirectional testing.} The PQC test automatically reports results for
both causal directions (x=>y and y=>x), allowing simultaneous assessment of
feedback effects.{p_end}

{pstd}
{bf:Notes on dmax}

{p 8 12 2}
The dmax parameter follows Toda and Yamamoto (1995). It adds dmax extra lags
to the VAR to ensure the Wald statistic has an asymptotic chi-squared distribution
regardless of the integration properties of the data. Set dmax equal to the
suspected maximum order of integration: dmax=1 if variables are at most I(1),
dmax=2 if possibly I(2). You do {it:not} need to pre-test for unit roots —
the method is valid for any combination of I(0), I(1), and I(2) variables.

{pstd}
{bf:Notes on Fourier terms (PFTY only)}

{p 8 12 2}
The Fourier terms sin(2*pi*f*t/T) and cos(2*pi*f*t/T) approximate unknown
structural breaks of any form (sharp, smooth, or gradual). Low frequencies
(f=1,2,3) are usually sufficient: f=1 captures a single smooth break, f=2
captures two, and f=3 captures more complex break patterns. Higher frequencies
are rarely needed and reduce parsimony (Enders and Lee 2012).

{pstd}
{bf:Graphs produced}

{p 8 12 2}{bf:PFTY:} (1) Bar chart of individual Wald statistics by panel, color-coded
by significance level (p<0.01, p<0.05, p<0.10), with Chi2(1) 5% critical value
shown as dashed line. (2) Bar plot of individual bootstrap p-values with 5% and
10% significance lines.{p_end}

{p 8 12 2}{bf:PQC:} Three combined panels: (1) Coefficient path plots showing the
quantile-varying causal effect for both directions. (2) Wald statistic plots with
5% Sup-Wald critical value as dashed line. (3) Bootstrap p-value plots with 5%
and 10% significance lines.{p_end}


{marker references}{...}
{title:References}

{phang}Chuang, C.C., Kuan, C.M. and Lin, H.Y. (2009).
Causality in quantiles and dynamic stock return-volume relations.
{it:Journal of Banking & Finance}, 33(7), 1351-1360.
{browse "https://doi.org/10.1016/j.jbankfin.2009.02.013"}{p_end}

{phang}Dumitrescu, E.I. and Hurlin, C. (2012).
Testing for Granger non-causality in heterogeneous panels.
{it:Economic Modelling}, 29(4), 1450-1460.
{browse "https://doi.org/10.1016/j.econmod.2012.02.014"}{p_end}

{phang}Emirmahmutoglu, F. and Kose, N. (2011).
Testing for Granger causality in heterogeneous mixed panels.
{it:Economic Modelling}, 28(3), 870-876.
{browse "https://doi.org/10.1016/j.econmod.2010.10.018"}{p_end}

{phang}Enders, W. and Lee, J. (2012).
The flexible Fourier form and Dickey-Fuller type unit root tests.
{it:Economics Letters}, 117(1), 196-199.
{browse "https://doi.org/10.1016/j.econlet.2012.04.081"}{p_end}

{phang}Koenker, R. and Bassett, G. (1978).
Regression quantiles.
{it:Econometrica}, 46(1), 33-50.
{browse "https://doi.org/10.2307/1913643"}{p_end}

{phang}Koenker, R. and Machado, J.A.F. (1999).
Goodness of fit and related inference processes for quantile regression.
{it:Journal of the American Statistical Association}, 94(448), 1296-1310.
{browse "https://doi.org/10.1080/01621459.1999.10473882"}{p_end}

{phang}Nazlioglu, S., Gormus, N.A. and Soytas, U. (2016).
Oil prices and real estate investment trusts (REITs):
Gradual-shift causality and volatility transmission analysis.
{it:Energy Economics}, 60, 168-175.
{browse "https://doi.org/10.1016/j.eneco.2016.09.009"}{p_end}

{phang}Toda, H.Y. and Yamamoto, T. (1995).
Statistical inference in vector autoregressions with possibly integrated processes.
{it:Journal of Econometrics}, 66(1-2), 225-250.
{browse "https://doi.org/10.1016/0304-4076(94)01616-8"}{p_end}

{phang}Wang, K.M. and Nguyen, T.B. (2022).
A quantile panel-type analysis of income inequality and healthcare expenditure.
{it:Economic Research-Ekonomska Istrazivanja}, 35(1), 873-893.
{browse "https://doi.org/10.1080/1331677X.2021.1952089"}{p_end}

{phang}Yilanci, V. and Gorus, M.S. (2020).
Does economic globalization have predictive power for ecological footprint:
Evidence from a panel causality test with a Fourier function.
{it:Environmental Science and Pollution Research}, 27, 40552-40562.
{browse "https://doi.org/10.1007/s11356-020-09895-x"}{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr. Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite as:{p_end}
{phang2}Roudane, M. (2026). xtpcaus: Panel causality tests with Fourier terms
and quantile regression. Stata module.{p_end}


{title:Also see}

{psee}
Online: {helpb xtgcause}, {helpb qreg}, {helpb var}, {helpb xtset}
{p_end}
