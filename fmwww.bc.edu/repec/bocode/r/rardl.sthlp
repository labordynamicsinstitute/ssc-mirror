{smcl}
{* *! version 1.1.0  23feb2026}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "var" "help var"}{...}
{vieweralsosee "vargranger" "help vargranger"}{...}
{viewerjumpto "Syntax" "rardl##syntax"}{...}
{viewerjumpto "Description" "rardl##description"}{...}
{viewerjumpto "Options" "rardl##options"}{...}
{viewerjumpto "Types" "rardl##types"}{...}
{viewerjumpto "Output" "rardl##output"}{...}
{viewerjumpto "Interpretation" "rardl##interpretation"}{...}
{viewerjumpto "Examples" "rardl##examples"}{...}
{viewerjumpto "Stored results" "rardl##stored"}{...}
{viewerjumpto "References" "rardl##references"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{bf:rardl} {hline 2}}Rolling-Window and Recursive ARDL Cointegration Analysis{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rardl} {depvar} {indepvars} [{it:if}] [{it:in}]{cmd:,}
{opt type(string)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt type(string)}}analysis type: {bf:rolling}, {bf:recursive}, {bf:radf}, {bf:rgranger}, or {bf:simulate}{p_end}

{syntab:Model specification}
{synopt:{opt maxlag(#)}}maximum lag length for ARDL/VAR; default is {bf:4}{p_end}
{synopt:{opt ic(string)}}information criterion for lag selection: {bf:aic}, {bf:bic}, or {bf:hqic}; default is {bf:bic}{p_end}
{synopt:{opt case(#)}}PSS model case (1-5); default is {bf:3}{p_end}
{synopt:{opt level(#)}}significance level: {bf:1}, {bf:5}, or {bf:10}; default is {bf:5}{p_end}

{syntab:Rolling-window options}
{synopt:{opt wsize(numlist)}}window size(s) in observations; default is {bf:60 120 180 240}{p_end}
{synopt:{opt allmodels}}estimate all 5 PSS models simultaneously{p_end}

{syntab:Recursive options}
{synopt:{opt initobs(#)}}initial sample size for expanding window; default is {bf:60}{p_end}
{synopt:{opt allcases}}estimate all PSS cases (2, 3, 5){p_end}
{synopt:{opt transform(string)}}{bf:level}, {bf:log}, or {bf:both}; default is {bf:level}{p_end}

{syntab:Recursive ADF options}
{synopt:{opt adfcase(string)}}{bf:2} (intercept), {bf:3} (intercept+trend), or {bf:all}; default is {bf:all}{p_end}
{synopt:{opt transform(string)}}{bf:level}, {bf:log}, {bf:diff}, {bf:dlog}, or {bf:all}; default is {bf:all}{p_end}

{syntab:Monte Carlo simulation}
{synopt:{opt nsim(#)}}number of Monte Carlo replications; default is {bf:50000}{p_end}
{synopt:{opt seed(#)}}random number seed for reproducibility{p_end}
{synopt:{opt nosimulate}}skip simulation, use asymptotic critical values from PSS (2001){p_end}

{syntab:Display and output}
{synopt:{opt graph}}produce publication-quality graphs{p_end}
{synopt:{opt notable}}suppress all table output{p_end}
{synoptline}
{p 4 6 2}* {opt type()} is required.{p_end}
{p 4 6 2}Data must be {helpb tsset} before using {cmd:rardl}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rardl} implements the Rolling-Window ARDL bounds testing approach of
Shahbaz, Khan & Mubarak (2023) and the Recursive ARDL, ADF, and Granger
causality tests of Khan, Shahbaz & Napari (2023). These methods evaluate
subsample stability and time-varying cointegration.

{pstd}
The core idea is to apply the Pesaran, Shin & Smith (2001) ARDL bounds test
not just once on the full sample, but repeatedly across overlapping
sub-samples (rolling windows) or expanding sub-samples (recursive). This
reveals {it:when} and {it:how} the long-run equilibrium relationship
changes over time.

{pstd}
The package provides five analysis types:

{phang2}{bf:rolling} {hline 1} Rolling-window ARDL bounds test. Applies
the ARDL ECM (Error Correction Model) over fixed-size rolling windows.
For each window, it estimates the model:

{p 12 12 2}D.y = c + {it:alpha}*L.y + {it:beta}*L.X + Sum({it:gamma_i}*L_i.D.y, i=1..p) + Sum({it:delta_j}*L_j.D.X, j=0..q) + e

{pmore2}Lag orders {bf:p} (for D.y) and {bf:q} (for D.X) are selected
separately via IC-based grid search over all ARDL(p,q) combinations.
The ARDL column in the output shows the selected (p,q) per window.
The F-statistic tests H0: {it:alpha} = {it:beta} = 0 (no long-run
relationship). Three tables are reported: {bf:Long-Run} (ECM, LR beta,
bounds F-test), {bf:Short-Run} (SR delta, SR F-test), and
{bf:Critical Value Comparison} (asymptotic vs simulated CVs with
I(0)/I(1) zone classification).{p_end}

{phang2}{bf:recursive} {hline 1} Recursive ARDL bounds test. Starts with
{it:initobs} observations and sequentially expands to the full sample,
re-estimating the ARDL(p,q) model at each step with separate lag selection.
Produces long-run, short-run, and CV comparison tables mapping the
evolution of relationships.{p_end}

{phang2}{bf:radf} {hline 1} Recursive Augmented Dickey-Fuller unit root
test. Applies expanding-window ADF tests to evaluate whether unit root
conclusions are stable across sample sizes. Tests multiple transformations
(level, log, differenced, diff-log) with automatic verdicts: "Consistent
Stationarity", "Consistent Non-stationarity", or "Mixed".{p_end}

{phang2}{bf:rgranger} {hline 1} Recursive Granger causality test. Tests
both directions of Granger causality (y1 -> y2 and y2 -> y1) using
expanding windows. A bivariate VAR is estimated at each sample size, and
the Granger F-statistic is normalized by critical values.{p_end}

{phang2}{bf:simulate} {hline 1} Standalone Monte Carlo simulation for
finite-sample critical values. Generates I(0) and I(1) critical bounds
for all 5 PSS model specifications at 1%, 5%, and 10% significance
levels. Based on the PSS (2001) DGP with independent random walks.
Includes a {bf:PSS vs Simulated comparison table} showing percentage
differences between asymptotic and finite-sample CVs for each model,
sample size, and significance level.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}{opt maxlag(#)} specifies the maximum number of lags considered
during automatic ARDL(p,q) lag selection. Separate optimal lags are
selected for the dependent variable (p = 1..maxlag) and independent
variables (q = 0..maxlag) using IC-based grid search over all (p,q)
combinations. Default is 4.{p_end}

{phang}{opt ic(string)} specifies the information criterion used for
automatic lag length selection: {bf:aic} (Akaike), {bf:bic} (Bayesian/
Schwarz, the default), or {bf:hqic} (Hannan-Quinn).{p_end}

{phang}{opt case(#)} specifies the PSS model case (deterministic
specification):

{p 8 13 2}Case 1: No intercept, no trend{p_end}
{p 8 13 2}Case 2: Restricted intercept, no trend{p_end}
{p 8 13 2}Case 3: Unrestricted intercept, no trend (default){p_end}
{p 8 13 2}Case 4: Unrestricted intercept, restricted trend{p_end}
{p 8 13 2}Case 5: Unrestricted intercept, unrestricted trend{p_end}

{phang}{opt level(#)} sets the significance level for hypothesis testing.
Allowed values are 1, 5, or 10; default is 5.{p_end}

{dlgtab:Rolling-window options}

{phang}{opt wsize(numlist)} specifies one or more window sizes (in
observations) for the rolling-window test. Multiple sizes can be specified
to compare results across different window widths. Default is 60 120 180
240.{p_end}

{phang}{opt allmodels} requests estimation for all 5 PSS model cases
simultaneously, rather than just the case specified in {opt case()}.{p_end}

{dlgtab:Recursive options}

{phang}{opt initobs(#)} sets the initial sample size for the expanding
window. The recursive procedure starts estimation with this many
observations and adds one observation at a time until the full sample is
reached. Default is 60. Must be larger than the number of parameters.{p_end}

{phang}{opt allcases} requests estimation for all default cases (2, 3, 5)
simultaneously.{p_end}

{phang}{opt transform(string)} specifies the data transformation:
{bf:level} (default) uses the raw variable, {bf:log} takes natural
logarithms, {bf:both} runs both level and log specifications.{p_end}

{dlgtab:Recursive ADF options}

{phang}{opt adfcase(string)} specifies the ADF regression specification:
{bf:2} includes an intercept, {bf:3} includes intercept and trend,
{bf:all} runs both. Default is {bf:all}.{p_end}

{phang}{opt transform(string)} specifies the variable transformation for
ADF testing: {bf:level} (raw), {bf:log} (natural log), {bf:diff} (first
difference), {bf:dlog} (differenced log), or {bf:all} (all four
transformations). Default is {bf:all}.{p_end}

{dlgtab:Monte Carlo simulation}

{phang}{opt nsim(#)} sets the number of Monte Carlo replications. Larger
values produce more precise critical values but take longer. Default is
50000. For quick testing, use 500-5000.{p_end}

{phang}{opt seed(#)} sets the random number seed for reproducible
simulation results.{p_end}

{phang}{opt nosimulate} skips Monte Carlo simulation and uses asymptotic
critical values from PSS (2001) Table CI instead. This is much faster but
may be imprecise for small samples (<80).{p_end}

{dlgtab:Display and output}

{phang}{opt graph} produces publication-quality graphs showing the
evolution of test statistics over time. For rolling/recursive ARDL, two
graphs are created: z-statistic and p-value plots with significance
thresholds. For RADF, z-ADF plots with unit-root threshold. For Granger,
z-GC plots per direction.{p_end}

{phang}{opt notable} suppresses all table output. Useful when only graphs
or stored results are needed.{p_end}

{marker types}{...}
{title:Analysis Types in Detail}

{dlgtab:rolling — Rolling-Window ARDL}

{pstd}
The rolling-window ARDL bounds test (RARDL) slides a fixed-size window
across the time series and computes the PSS bounds F-test at each
position. This captures {bf:time-varying cointegration}. Key parameters:

{phang2}• The normalized z-statistic: z_bt = F / UCV{p_end}
{phang2}• Cointegration detected when z_bt > 1{p_end}
{phang2}• ECM coefficient ({it:alpha}) shows speed of adjustment{p_end}
{phang2}• Long-run coefficient ({it:beta}) shows L.X effect{p_end}
{phang2}• Short-run coefficient ({it:delta}) shows D.X effect{p_end}

{pstd}
Output includes two organized tables per model/window:

{phang2}{bf:Long-Run Results table}: Period, ECM({it:alpha}), LR({it:beta}), F-bounds, UCV,
z-bt, Decision (*** = cointegration){p_end}

{phang2}{bf:Short-Run Results table}: Period, SR({it:delta}), SR F-stat, p-value,
Decision (*** = significant), ECM({it:alpha}), LR Decision{p_end}

{dlgtab:recursive — Recursive ARDL}

{pstd}
The recursive ARDL uses an expanding window starting from {it:initobs}.
The main advantage over rolling windows is that it avoids window size
selection and uses all available information. The output structure is
identical to rolling, with separate Long-Run and Short-Run tables.

{dlgtab:radf — Recursive ADF}

{pstd}
Applies the ADF unit root test with expanding windows. For each variable
and transformation, a detailed table shows:

{phang2}End Period, t-statistic, Critical Value, z-ADF, Decision{p_end}

{pstd}
Verdicts are assigned based on the proportion of rejections:

{phang2}• >=95% reject: "Consistent Stationarity"{p_end}
{phang2}• >=80% reject: "Stationarity w/ exceptions"{p_end}
{phang2}• 50-80%: "Mixed evidence"{p_end}
{phang2}• 20-50%: "Non-stationarity w/ exceptions"{p_end}
{phang2}• <5%: "Consistent Non-stationarity"{p_end}

{dlgtab:rgranger — Recursive Granger Causality}

{pstd}
Tests both directions of Granger causality using expanding windows.
For variables y1 and y2, a bivariate VAR is estimated at each sample
size, and the Wald/F-test for Granger non-causality is computed.

{pstd}
Output shows a bidirectional table:

{phang2}Period, F(y2 -> y1), z-GC, Decision, F(y1 -> y2), z-GC, Decision{p_end}

{pstd}
Where z-GC = F / CV(alpha). The *** marker indicates rejection of the
no-causality null (i.e., Granger causality is detected).

{dlgtab:simulate — Monte Carlo Critical Values}

{pstd}
Generates finite-sample critical bounds for the ARDL F-test. The DGP
follows Pesaran et al. (2001): y is a random walk, X variables are
either I(0) (AR(1) with phi=0.5) or I(1) (random walk). Critical
bounds are the 90th, 95th, and 99th percentiles of the simulated
F-statistics.

{pstd}
Output is a table for each of the 5 PSS models showing I(0) and I(1)
bounds at 1%, 5%, and 10% significance levels for each sample size.

{marker output}{...}
{title:Output Description}

{dlgtab:Summary statistics}

{pstd}
Each test type first displays a summary showing:

{phang2}• Number of windows/tests performed{p_end}
{phang2}• Proportion showing cointegration/stationarity/causality{p_end}
{phang2}• First and last dates of significance{p_end}
{phang2}• Overall verdict{p_end}

{dlgtab:Detailed tables}

{pstd}
Below each summary, a sampled table of approximately 20 rows is
displayed, covering the full estimation period at regular intervals.
The table always includes the first and last observations.

{dlgtab:Graphs}

{pstd}
When {opt graph} is specified, the following plots are produced:

{phang2}{bf:z-statistic plot}: Shows the evolution of z = F/UCV with a
dashed red threshold line at z = 1. Green shaded areas indicate
cointegration periods (z > 1).{p_end}

{phang2}{bf:p-value plot} (rolling only): Shows rolling p-values with
horizontal dashed lines at 1%, 5%, and 10% significance.{p_end}

{phang2}{bf:z-ADF plot} (radf): Shows z_ADF with threshold at 1 and
shaded rejection/non-rejection regions.{p_end}

{phang2}{bf:z-GC plot} (rgranger): Shows Granger causality z-statistic
per direction with threshold at 1.{p_end}

{pstd}
All graphs are automatically exported as PNG files (1400px width) in the
current working directory.

{marker interpretation}{...}
{title:Interpretation Guide}

{pstd}
This section explains how to read and interpret {cmd:rardl} output with
concrete examples. Each subsection corresponds to a test type.

{dlgtab:Interpreting the Long-Run Table (rolling / recursive)}

{pstd}
The Long-Run table tests for {bf:cointegration} (long-run equilibrium
relationship) at each window or expanding sample. Consider this output:

{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}{bf:Long-Run Results (Cointegration)}{p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  Period    ECM(a)    LR(b)   F-bounds   UCV    z-bt   Dec{p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  1990m6   -0.0259   0.0413     3.134   5.730  0.547      {p_end}
{p 4 4 2}  2010m4   -0.2685   0.4518     4.532   5.730  0.791      {p_end}
{p 4 4 2}  2015m12  -0.0333   0.7214     7.095   5.730  1.238  ***{p_end}
{p 4 4 2}{hline 78}{p_end}

{pstd}
{bf:How to read each column:}

{phang2}• {bf:ECM(a)} = Error Correction coefficient (alpha): speed of adjustment
toward equilibrium. Should be {bf:negative and significant} for valid
cointegration. Values near 0 suggest no adjustment; values near -1 suggest
rapid correction. Example: ECM = -0.2685 means 26.85% of disequilibrium is
corrected each period.{p_end}

{phang2}• {bf:LR(b)} = Long-run coefficient (beta) on L.X: the estimated
long-run elasticity. A 1-unit increase in X is associated with a {it:beta}-unit
change in Y in the long run. Example: LR(b) = 0.4518 means a $1 rise in
silver is associated with a $0.45 rise in oil in long-run equilibrium.{p_end}

{phang2}• {bf:F-bounds} = PSS bounds F-statistic testing H0: alpha = beta = 0
(no level relationship). Larger values suggest stronger evidence of
cointegration.{p_end}

{phang2}• {bf:UCV} = Upper critical value at the specified significance level.
When F > UCV, we reject H0 and conclude cointegration regardless of whether
regressors are I(0) or I(1).{p_end}

{phang2}• {bf:z-bt} = Normalized statistic = F / UCV. When z-bt > 1,
F exceeds the upper bound (cointegration confirmed). Values between
LCV/UCV and 1 are inconclusive.{p_end}

{phang2}• {bf:Dec} = Decision: *** indicates cointegration (z-bt > 1).{p_end}

{pstd}
{bf:Interpretation of the row for 2015m12:} The bounds F-test (7.095) exceeds
the UCV (5.730), giving z-bt = 1.238 > 1. This indicates cointegration during
the window ending December 2015. The ECM coefficient (-0.033) is negative,
suggesting adjustment toward equilibrium (though slow). The LR beta (0.721)
indicates a positive long-run relationship.

{pstd}
{bf:Interpretation of the row for 1990m6:} F = 3.134 < UCV = 5.730, so
z-bt = 0.547 < 1. No cointegration in this window. Even though ECM is
negative, the bounds test fails to confirm a statistically significant
level relationship.

{dlgtab:Interpreting the Short-Run Table (rolling / recursive)}

{pstd}
The Short-Run table tests for {bf:short-run dynamics} — whether changes
in X have an immediate effect on changes in Y:

{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}{bf:Short-Run Results (Dynamics)}{p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  Period    SR(d)    SR F     p-val    Dec   ECM(a)  LR Dec{p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  1990m6   0.1823    5.421   0.0016  ***   -0.0259        {p_end}
{p 4 4 2}  2010m4   0.3150    2.873   0.0418  ***   -0.2685        {p_end}
{p 4 4 2}  2015m12  0.0213    0.341   0.7952        -0.0333    *** {p_end}
{p 4 4 2}{hline 78}{p_end}

{phang2}• {bf:SR(d)} = Short-run coefficient (delta) on D.X: the immediate
impact of a change in X on the change in Y. Example: SR(d) = 0.315 means a
$1 change in silver leads to an immediate $0.315 change in oil.{p_end}

{phang2}• {bf:SR F-stat} = Joint F-test for all differenced X terms (D.X and
its lags). A significant SR F-test means short-run dynamics exist.{p_end}

{phang2}• {bf:p-val} = P-value of the SR F-test. Values < 0.05 are
significant at 5%.{p_end}

{phang2}• {bf:LR Dec} = Cross-reference showing whether cointegration was also
found in this window (from the Long-Run table).{p_end}

{pstd}
{bf:Key insight — comparing LR and SR:} A window can show significant
short-run dynamics WITHOUT long-run cointegration (1990m6: SR *** but no
LR ***), or long-run cointegration WITHOUT significant short-run effects
(2015m12: LR *** but no SR ***). The ideal case is when both are
significant, confirming both the equilibrium relationship and the
transmission mechanism.

{dlgtab:Interpreting RADF (Recursive ADF) output}

{pstd}
The RADF table shows whether a variable's stationarity status is
stable across different sample sizes:

{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  Period    t-stat    CV(5%)    z-ADF    Decision{p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  1976m4   -2.8325   -2.8741   0.9855   Fail   {p_end}
{p 4 4 2}  1987m8   -1.5858   -2.8683   0.5529   Fail   {p_end}
{p 4 4 2}{hline 78}{p_end}

{phang2}• {bf:t-stat} = ADF t-statistic. More negative = stronger evidence
against unit root.{p_end}

{phang2}• {bf:CV(5%)} = Critical value at 5%. Reject unit root when t-stat < CV
(i.e., more negative).{p_end}

{phang2}• {bf:z-ADF} = |t-stat / CV|. When z-ADF > 1, the t-stat exceeds the
critical value (reject unit root = variable is stationary).{p_end}

{phang2}• {bf:Decision} = "Reject" (stationary) or "Fail" (unit root).{p_end}

{pstd}
{bf:Verdict interpretation:} If the verdict is "Consistent
Non-stationarity" (0% rejection), the variable contains a unit root
across all sample sizes — standard for asset prices. If "Consistent
Stationarity" (>95% rejection), the variable is I(0). "Mixed evidence"
suggests a structural break may have changed the integration order.

{dlgtab:Interpreting Granger Causality output}

{pstd}
The Granger causality table shows both causal directions:

{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  Period   F(gold)  z-GC  Dec   F(oil)   z-GC  Dec{p_end}
{p 4 4 2}          -> oil                -> gold          {p_end}
{p 4 4 2}{hline 78}{p_end}
{p 4 4 2}  1976m4    1.076  0.277         6.306  1.621  ***{p_end}
{p 4 4 2}  2013m2    0.039  0.010         0.126  0.033     {p_end}
{p 4 4 2}{hline 78}{p_end}

{phang2}• {bf:F(gold) -> oil}: F-statistic testing whether lagged gold values
help predict oil. *** means gold Granger-causes oil.{p_end}

{phang2}• {bf:F(oil) -> gold}: F-statistic for the reverse direction.{p_end}

{phang2}• {bf:z-GC} = F / CV. When z-GC > 1, causality is significant.{p_end}

{pstd}
{bf:How to interpret:} In 1976m4, oil Granger-causes gold (z = 1.621 > 1)
but gold does NOT Granger-cause oil (z = 0.277 < 1). This is
{bf:unidirectional causality} from oil to gold. By 2013m2, neither direction
shows causality ({bf:no causal relationship} in this period).

{pstd}
{bf:Possible patterns:}

{phang2}• Both *** = Bidirectional (feedback) causality{p_end}
{phang2}• One *** = Unidirectional causality{p_end}
{phang2}• Neither *** = No Granger causality{p_end}
{phang2}• Pattern changes over time = time-varying causal structure{p_end}

{dlgtab:Interpreting Verdicts}

{pstd}
The overall verdict summarizes the proportion of windows/iterations
showing significance:

{p 4 4 2}{hline 66}{p_end}
{p 4 4 2}  Verdict                        Percentage  Meaning{p_end}
{p 4 4 2}{hline 66}{p_end}
{p 4 4 2}  Cointegration                  >= 95%      Robust LR relationship{p_end}
{p 4 4 2}  Coint. w/ rare exceptions      >= 80%      Mostly stable{p_end}
{p 4 4 2}  Coint. w/ exceptions           >= 50%      Evidence exists{p_end}
{p 4 4 2}  Inconsistent                   20-50%      Unreliable{p_end}
{p 4 4 2}  No coint. w/ rare exceptions   5-20%       Mostly absent{p_end}
{p 4 4 2}  No cointegration               < 5%        No evidence{p_end}
{p 4 4 2}{hline 66}{p_end}

{pstd}
{bf:For academic papers}, the most informative strategy is to combine
rolling and recursive approaches: concordant results strengthen the
conclusion. If the rolling test shows cointegration in a certain period
and the recursive test also shows structural change around that time,
the evidence is robust.

{dlgtab:Writing up results}

{pstd}
{bf:Example write-up for a paper:}

{pstd}
"The rolling-window ARDL bounds test with a 60-month window reveals
that the long-run relationship between oil and silver is unstable.
Cointegration is detected in only 8% of windows, concentrated around
2015-2016. The ECM coefficient ranges from -0.268 to 0.091, indicating
varying speeds of adjustment. Short-run dynamics are more persistent,
with the SR F-test significant in 42% of windows, suggesting temporary
pass-through effects even in the absence of a stable equilibrium.
The recursive Granger causality test reveals unidirectional causality
from oil to gold during 1976-1985, which disappears in recent periods."

{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}: Load monthly commodity price data (oil, silver, gold) and declare time series.{p_end}
{phang2}{cmd:. import excel "commodity_data.xlsx", firstrow clear}{p_end}
{phang2}{cmd:. gen t = tm(1960m1) + _n - 1}{p_end}
{phang2}{cmd:. format t %tm}{p_end}
{phang2}{cmd:. tsset t, monthly}{p_end}

{dlgtab:Example 1: Recursive ADF unit root test}

{pstd}Test stationarity of oil across all transformations:{p_end}
{phang2}{cmd:. rardl oil, type(radf) initobs(60) transform(all) adfcase(all) maxlag(4) graph}{p_end}

{pstd}This produces tables and graphs for each combination of
transformation (level, log, diff, dlog) and ADF case (2, 3), with
automatic verdicts.{p_end}

{dlgtab:Example 2: Monte Carlo simulation}

{pstd}Generate critical values for common sample sizes:{p_end}
{phang2}{cmd:. rardl oil gold, type(simulate) wsize(60 120 180 240) nsim(5000) seed(12345)}{p_end}

{pstd}Displays I(0)/I(1) critical bounds for all 5 PSS models at 1%, 5%,
and 10% significance. Use {it:nsim(50000)} for publication-quality
results.{p_end}

{dlgtab:Example 3: Rolling-window ARDL with asymptotic CVs}

{pstd}Quick rolling test using PSS (2001) asymptotic critical values:{p_end}
{phang2}{cmd:. rardl oil silver, type(rolling) case(3) wsize(60 120) maxlag(4) nosimulate graph}{p_end}

{pstd}Displays Long-Run and Short-Run tables for each window size, plus
z-statistic and p-value graphs.{p_end}

{dlgtab:Example 4: Rolling-window ARDL with simulated CVs}

{pstd}Full rolling test with Monte Carlo simulated critical values:{p_end}
{phang2}{cmd:. rardl oil silver, type(rolling) case(3) wsize(60 120) nsim(5000) seed(42) graph}{p_end}

{dlgtab:Example 5: Recursive ARDL}

{pstd}Recursive test with level and log transformations:{p_end}
{phang2}{cmd:. rardl oil silver, type(recursive) initobs(60) case(3) transform(both) nosimulate graph}{p_end}

{pstd}Produces separate Long-Run and Short-Run tables for each
transformation, showing how cointegration evolves as the sample
expands.{p_end}

{dlgtab:Example 6: Recursive Granger causality}

{pstd}Test both directions of Granger causality:{p_end}
{phang2}{cmd:. rardl oil gold, type(rgranger) initobs(60) maxlag(4) transform(both) graph}{p_end}

{pstd}Displays bidirectional F-statistics, z-GC, and decisions per period.
Separate results for level and log prices.{p_end}

{dlgtab:Example 7: All PSS models}

{pstd}Compare all 5 PSS model specifications:{p_end}
{phang2}{cmd:. rardl oil silver, type(rolling) wsize(120) allmodels nosimulate graph}{p_end}

{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:rardl} stores the following in {cmd:r()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:r(maxlag)}}maximum lag length{p_end}
{synopt:{cmd:r(level)}}significance level{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}rardl{p_end}
{synopt:{cmd:r(type)}}analysis type{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(cmdline)}}full command line{p_end}
{synopt:{cmd:r(ic)}}information criterion used{p_end}

{pstd}
Each sub-command stores additional matrices:

{dlgtab:rolling stored results}

{synoptset 32 tabbed}{...}
{synopt:{cmd:r(roll_m{it:M}_w{it:W})}}result matrix for Model {it:M}, Window {it:W}.
Columns: start_obs, end_obs, F_stat, pval, z_bt, ecm_coef, lr_beta, sr_delta, sr_fstat.{p_end}

{dlgtab:recursive stored results}

{synopt:{cmd:r(rec_c{it:C}_lev)}}result matrix for Case {it:C}, level transformation.
Columns: end_obs, F_stat, UCV, z_bt, ecm_coef, lr_beta, sr_delta, sr_fstat.{p_end}
{synopt:{cmd:r(rec_c{it:C}_log)}}same for log transformation.{p_end}
{synopt:{cmd:r(verdict_c{it:C}_lev)}}overall verdict string.{p_end}

{dlgtab:radf stored results}

{synopt:{cmd:r(zadf_{it:var}_{it:tr}_c{it:C})}}ZADF matrix. Columns: end_obs, t_stat, cv, z_adf.{p_end}

{dlgtab:rgranger stored results}

{synopt:{cmd:r(gc_21_{it:tr})}}Granger causality matrix for direction 2->1.
Columns: end_obs, F_stat, CV, z_gc.{p_end}
{synopt:{cmd:r(gc_12_{it:tr})}}same for direction 1->2.{p_end}

{dlgtab:simulate stored results}

{synopt:{cmd:r(cv_model{it:M})}}critical value matrix for Model {it:M}.
Columns: T, LB_1pct, UB_1pct, LB_5pct, UB_5pct, LB_10pct, UB_10pct.{p_end}
{synopt:{cmd:r(nsim)}}number of replications.{p_end}
{synopt:{cmd:r(nregs)}}number of regressors.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr. Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{marker references}{...}
{title:References}

{phang}
Khan, A.U.I., Shahbaz, M., & Napari, A. (2023).
Subsample stability, change detection and dynamics of oil and metal markets:
A recursive approach.
{it:Resources Policy}, 83, 103601.{p_end}

{phang}
Pesaran, M.H., Shin, Y., & Smith, R.J. (2001).
Bounds testing approaches to the analysis of level relationships.
{it:Journal of Applied Econometrics}, 16(3), 289-326.{p_end}

{phang}
Shahbaz, M., Khan, A.I., & Mubarak, M.S. (2023).
Rolling-window bounds testing approach to analyze the relationship between
oil prices and metal prices.
{it:The Quarterly Review of Economics and Finance}, 87, 388-395.{p_end}

{title:Also see}

{psee}
{space 2}Help: {helpb ardl}, {helpb dfuller}, {helpb var}, {helpb vargranger}
{p_end}
