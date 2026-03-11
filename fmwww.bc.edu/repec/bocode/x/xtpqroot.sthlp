{smcl}
{* *! version 1.0.2  06mar2026}{...}
{vieweralsosee "xtcips" "help xtcips"}{...}
{vieweralsosee "pescadf" "help pescadf"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{viewerjumpto "Syntax" "xtpqroot##syntax"}{...}
{viewerjumpto "Description" "xtpqroot##description"}{...}
{viewerjumpto "Options" "xtpqroot##options"}{...}
{viewerjumpto "Output" "xtpqroot##output"}{...}
{viewerjumpto "Interpretation" "xtpqroot##interpretation"}{...}
{viewerjumpto "Notes" "xtpqroot##notes"}{...}
{viewerjumpto "Examples" "xtpqroot##examples"}{...}
{viewerjumpto "Stored results" "xtpqroot##stored"}{...}
{viewerjumpto "References" "xtpqroot##references"}{...}
{viewerjumpto "Authors" "xtpqroot##authors"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:xtpqroot} {hline 2}}Panel Quantile Unit Root Tests with Common Shocks & Structural Breaks{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
{bf:CIPS(tau) Test} (Yang, Wei & Cai 2022; Nazlioglu et al. 2026):

{p 8 16 2}
{cmd:xtpqroot} {varname} {ifin}{cmd:,}
[{opt q:uantile(numlist)}
{opt m:odel(string)}
{opt maxl:ag(#)}
{opt reps(#)}
{opt nog:raph}
{opt not:able}
{opt l:evel(#)}
{opt cd:test}
{opt ind:ividual}]

{phang}
{bf:tFR Test} (Corakci & Omay 2023):

{p 8 16 2}
{cmd:xtpqroot} {varname} {ifin}{cmd:,}
{opt four:ier}
[{opt m:odel(string)}
{opt maxl:ag(#)}
{opt bootr:eps(#)}
{opt nog:raph}
{opt not:able}
{opt l:evel(#)}]

{p 4 6 2}
Panel data must be declared using {helpb xtset}. The panel must be {bf:strongly balanced}
(no gaps or missing observations).


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqroot} implements two novel panel unit root tests designed for panel data
with cross-sectional dependence (CSD):

{phang2}
{bf:1. CIPS(tau) Test}: Quantile panel unit root test with common shocks, proposed by
Yang, Wei & Cai (2022, {it:Economics Letters}). It extends Pesaran's (2007) CIPS test
to a quantile regression framework, allowing the analysis of {bf:asymmetric persistence}
across different quantiles of the conditional distribution. While the standard CIPS
test assesses the mean persistence, CIPS(tau) can detect, for example, whether a series
is more persistent in extreme quantiles than in the center. Implementation follows
Nazlioglu, Tarakci, Karul & Erdem (2026, {it:NAJEF}).{p_end}

{phang2}
{bf:2. tFR Test}: Panel unit root test with smooth and sharp structural breaks,
proposed by Corakci & Omay (2023, {it:Renewable Energy}). It combines the fractional
Fourier function (for smooth, gradual breaks) with the logistic smooth transition (LST)
function (for sharp, abrupt breaks). This allows the test to capture {bf:both types of
structural change simultaneously}. Cross-sectional dependence is corrected via the
sieve bootstrap procedure of Chang (2004).{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Common Options}

{phang}
{opt model(string)} specifies the deterministic component of the regression.{p_end}

{phang2}
For {bf:CIPS(tau)}: {opt intercept} (default) includes only a constant;
{opt trend} adds a linear time trend.{p_end}

{phang2}
For {bf:tFR}: {opt intercept} estimates Model A (intercept shift only);
{opt trend} estimates Model B (intercept shift + linear trend);
{opt trendshift} estimates Model C (both intercept and trend shift). The choice
of model should match the data generating process: use {opt intercept} for level
shifts, {opt trend} if the series has a trend, and {opt trendshift} if you suspect
both the level and trend slope may change.{p_end}

{phang}
{opt maxlag(#)} specifies the maximum lag order for augmented regressions. The
default is automatic: p = floor[4(T/100)^{c -(}1/4{c )-}], following Schwert (1989)
and Pesaran (2007). For the Fourier test, the maximum is capped at 6 and the
optimal lag within each panel is selected by the Schwarz information criterion (SIC).

{phang}
{opt nograph} suppresses all graphical output.

{phang}
{opt notable} suppresses all tabular output.

{phang}
{opt level(#)} sets the confidence level for inference. Default is 95.

{dlgtab:CIPS(tau) Options}

{phang}
{opt quantile(numlist)} specifies the quantile(s) at which to run the CIPS(tau) test.
Values must be strictly between 0 and 1. Default: 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9.

{phang}
{opt reps(#)} specifies the number of Monte Carlo replications used to simulate
the empirical distribution of CIPS and CIPS(tau) under H0 (unit root in all panels).
Default is 1000. Larger values improve p-value precision but increase computation
time. For preliminary work, {opt reps(200)} is often sufficient.

{phang}
{opt cdtest} additionally reports the Pesaran (2004, 2021) CD test for cross-sectional
dependence, computed from both OLS and quantile regression residuals. Significant CD
statistics suggest that cross-sectional dependence is present and that standard panel
unit root tests (e.g., IPS, LLC) may be oversized.

{phang}
{opt individual} displays the individual panel-level CADF and CADF(tau) test statistics,
along with panel-specific p-values from the Monte Carlo simulation. This is useful to
identify {bf:which specific panels} reject the unit root hypothesis.

{dlgtab:tFR Options}

{phang}
{opt fourier} selects the Corakci & Omay (2023) tFR test rather than the CIPS(tau) test.
Cannot be combined with {opt quantile()}.

{phang}
{opt bootreps(#)} specifies the number of sieve bootstrap replications for computing
bootstrap p-values and critical values. Default is 2000. Larger values improve the
precision of the bootstrap distribution.


{marker output}{...}
{title:Output Description}

{dlgtab:CIPS(tau) Output}

{pstd}
The CIPS(tau) output consists of the following sections:

{phang}
{bf:Data Summary}: Displays the variable name, panel structure (panel/time variables,
N panels, T time periods, total observations), deterministic specification
(Intercept only or Intercept + Trend), lag order, MC replications, and
truncation constants (K1, K2) used for the Pesaran (2007) truncation procedure.{p_end}

{phang}
{bf:Panel Unit Root Tests}: Reports the standard OLS-based CIPS statistic (Pesaran 2007)
with its Monte Carlo p-value. This provides a baseline for comparison.{p_end}

{phang}
{bf:CIPS(tau) (Quantile Panel Unit Root)}: Reports the quantile-specific CIPS(tau)
statistic, p-value, significance stars, and rejection decision at each requested
quantile tau. More negative CIPS(tau) values indicate stronger evidence against
the null.{p_end}

{phang}
{bf:Cross-Sectional Dependence Tests} (with {opt cdtest}): Reports the Pesaran (2021)
CD statistic and p-value from OLS residuals, followed by CD(tau) at each quantile
from quantile regression residuals.{p_end}

{phang}
{bf:Hypotheses}: States the null and alternative hypotheses and provides guidance
on interpreting asymmetric persistence patterns.{p_end}

{phang}
{bf:Individual Panel Results} (with {opt individual}): Displays rho(OLS) and
rho(tau) for each panel, with significance stars based on individual CADF
p-values from the MC simulation. A summary line shows the number of panels
rejecting H0 at each quantile.{p_end}

{phang}
{bf:Footer}: Significance levels are denoted as *** p<0.01, ** p<0.05, * p<0.10.
Source references: Yang, Wei & Cai (2022, Econ. Letters);
Nazlioglu et al. (2026, NAJEF).{p_end}

{phang}
{bf:Graphs}: Two publication-quality graphs are produced by default:
(1) CIPS(tau) statistic plotted across quantiles, and
(2) Persistence degree rho(tau) across quantiles with confidence bands
(mean across panels with 10%-90% range).{p_end}

{dlgtab:tFR Output}

{pstd}
The tFR output consists of the following sections:

{phang}
{bf:Data Summary}: Displays the variable name, panel structure, model type
(A: Intercept shift, B: Intercept shift + Trend, C: Intercept + Trend shift),
CSD correction method (Sieve Bootstrap), bootstrap replications, maximum ADF
lag, and lag selection criterion (SIC).{p_end}

{phang}
{bf:Panel Test Result}: Reports the tFR panel statistic (cross-sectional average
of individual Fourier ADF t-statistics), bootstrap p-value, and significance
stars.{p_end}

{phang}
{bf:Bootstrap Critical Values}: Reports critical values at the 1%, 5%, and 10%
significance levels from the sieve bootstrap, along with the tFR statistic and
a decision column indicating Reject H0 or Fail to reject H0 at each level.{p_end}

{phang}
{bf:Individual Panel Results}: For each panel, displays:{p_end}
{phang2}{opt t_i,fr} {hline 1} the Fourier ADF t-statistic for panel i{p_end}
{phang2}{opt k^fr} {hline 1} the optimal fractional Fourier frequency (controls break shape){p_end}
{phang2}{opt gamma} {hline 1} the LST transition speed (large = sharp, small = gradual){p_end}
{phang2}{opt tau} {hline 1} the estimated break location (fraction of sample){p_end}
{phang2}{opt Break Date} {hline 1} the estimated calendar date of the structural break{p_end}
{phang2}{opt SIC p} {hline 1} the optimal ADF lag selected by the Schwarz criterion{p_end}
{phang2}Significance stars (* ** ***) compare individual t_i,fr to bootstrap CVs.{p_end}

{phang}
{bf:Sharp and Smooth Break Dates}: A summary table (matching Table 6 in
Corakci & Omay 2023) listing each panel's sharp break date (from the LST logistic
function threshold) and smooth break dates (from the Fourier function turning
points).{p_end}

{phang}
{bf:Hypotheses}: States the null (H0: all panels contain a unit root) and
alternative (H1: some panels are stationary).{p_end}

{phang}
{bf:Footer}: Significance levels *** p<0.01, ** p<0.05, * p<0.10.
Source reference: Corakci & Omay (2023, Renewable Energy).{p_end}

{phang}
{bf:Graphs}: Two publication-quality graphs are produced by default:
(1) Actual vs. fitted (LST + Fourier) curves for each panel as small multiples, and
(2) Individual t(i,FR) statistics as a bar chart with bootstrap 5% critical value
line and color-coded significance.{p_end}


{marker interpretation}{...}
{title:Interpretation Guide}

{dlgtab:CIPS(tau) Test}

{pstd}
{bf:Hypotheses:}{p_end}

{phang2}
H0: rho_i(tau) = 1 for all panels i and all quantiles tau {hline 1}
all panels contain a unit root.{p_end}

{phang2}
H1: rho_i(tau) < 1 for some panels i {hline 1}
some panels are stationary (at the given quantile).{p_end}

{pstd}
{bf:Reading the output table:} The CIPS(tau) statistic is the cross-sectional average
of individual CADF(tau) t-statistics. More negative values indicate stronger evidence
against the null of a unit root. The p-values are obtained from Monte Carlo simulation
under the null hypothesis.{p_end}

{pstd}
{bf:Significance stars:} *** p<0.01, ** p<0.05, * p<0.10. Stars appear next to
p-values and individual rho estimates to indicate rejection of H0 at the
corresponding significance level.{p_end}

{pstd}
{bf:Asymmetric persistence patterns:}{p_end}

{phang2}
{it:Reject at low tau but not high tau}: The variable is mean-reverting during
normal/low periods but persistent during extreme positive shocks (e.g., high
inflation episodes are persistent, but low inflation reverts to mean).{p_end}

{phang2}
{it:Reject at high tau but not low tau}: The opposite asymmetry; the variable
is persistent during contractionary episodes.{p_end}

{phang2}
{it:Reject across all tau}: Strong evidence of overall stationarity. The unit
root can be rejected uniformly across the distribution.{p_end}

{phang2}
{it:Fail to reject at all tau}: Consistent with a unit root across the entire
distribution.{p_end}

{pstd}
{bf:Persistence graph:} The rho(tau) graph plots the autoregressive coefficient at
each quantile. Values of rho(tau) >= 1 indicate a unit root (persistence) at that
quantile, while rho(tau) < 1 indicates mean-reversion. The graph provides a visual
summary of asymmetric persistence across the distribution.{p_end}

{dlgtab:tFR Test}

{pstd}
{bf:Hypotheses:}{p_end}

{phang2}
H0: phi_i = 0 for all panels i {hline 1} all panels contain a unit root.{p_end}

{phang2}
H1: phi_i < 0 for some panels i {hline 1} some panels are stationary.{p_end}

{pstd}
{bf:Reading the output:} The tFR statistic is the cross-sectional average of individual
Fourier ADF t-statistics. The bootstrap p-value and critical values are derived from the
sieve bootstrap. Reject the null if tFR is less than the bootstrap critical value at
the chosen significance level, or equivalently, if the bootstrap p-value is below the
chosen alpha.{p_end}

{pstd}
{bf:Individual panel statistics:} Large negative t_i,fr values indicate stronger
evidence of stationarity for that panel. Stars indicate significance relative to
the bootstrap critical values. The gamma parameter controls the sharpness of the
LST break: gamma > 10 indicates a sharp, abrupt structural break; gamma < 1
indicates a gradual transition. The tau parameter (0 to 1) locates the break
within the sample period.{p_end}

{pstd}
{bf:Break dates table:} Sharp break dates correspond to the estimated location
of the logistic smooth transition function. Smooth break dates are the turning
points (peaks and troughs) of the estimated Fourier function. Panels with
very low k^fr (e.g., k < 0.2) may show no smooth break dates within the sample.{p_end}


{marker notes}{...}
{title:Notes and Warnings}

{dlgtab:Data Requirements}

{phang}
{err:Balanced panel required.} The panel must be strongly balanced {hline 1} each panel
unit must have the same number of time periods with no gaps. Use {helpb xtdescribe} to
verify the panel structure before running {cmd:xtpqroot}.{p_end}

{phang}
{err:Minimum dimensions.} The test requires at least N >= 3 panels and T >= 15 time
periods. Very small T (below 20) may produce unreliable results. The test is designed
for panels where both N and T are reasonably large.{p_end}

{dlgtab:Computation Time}

{phang}
{bf:CIPS(tau) test:} Computation time grows with N * nq * reps, where nq is the
number of quantiles. For large panels (N > 100), {opt reps(100)} may take several
minutes. Use {opt reps(200)} for preliminary work and increase to {opt reps(1000)}
or more for final published results.{p_end}

{phang}
{bf:tFR test:} The Fourier grid search (Step 1-2) and sieve bootstrap (Step 3) are
both computationally intensive. The grid search uses Mata-compiled matrix algebra
for speed. Use {opt bootreps(500)} for preliminary work.{p_end}

{phang}
{bf:Graphs:} When graphs are enabled (the default), the CIPS(tau) test computes
rho(tau) at 99 quantile points per panel. For very large N, use {opt nograph} to
save time during preliminary analysis, then re-run with graphs for final
results.{p_end}

{dlgtab:Methodology Notes}

{phang}
{bf:Cross-sectional dependence:} The CIPS(tau) test handles CSD by including
cross-sectional averages (ybar, Dybar) as auxiliary regressors in the CADF regression,
following Pesaran (2007). The tFR test handles CSD via the sieve bootstrap, which
preserves the cross-panel correlation structure by resampling full time-period rows
of centered residuals.{p_end}

{phang}
{bf:Truncation:} Following Pesaran (2007, p.35), individual CADF statistics are
truncated at [-K1, K2] before averaging. This ensures that the CIPS statistic has
finite moments even when some individual panel statistics are extreme. The truncation
constants are K1=6.19 for both models and K2=2.16 (intercept) or K2=2.61 (trend).
Un-truncated statistics are used for individual panel p-value calculations.{p_end}

{phang}
{bf:Sparsity estimation:} The standard error of the quantile autoregressive coefficient
uses the Koenker & Xiao (2004) bandwidth for kernel density estimation at the residual
quantiles. This avoids the VCE failures that occur with Stata's built-in {cmd:qreg}
at extreme quantiles.{p_end}

{phang}
{bf:Fourier frequency:} The tFR test searches over fractional frequencies
k^fr in [0.1, 5.0] (step size 0.1), selecting the value that minimizes the sum of
squared residuals. Unlike integer Fourier tests, fractional frequencies provide a
more flexible representation of smooth structural change.{p_end}

{phang}
{bf:LST transition function:} The logistic smooth transition function
F(t) = 1/(1 + exp(-gamma*(t/T - tau))) captures sharp structural breaks. The
parameter gamma controls the speed of transition (gamma -> infinity yields a
step function), and tau in (0,1) determines the break location. The grid search
evaluates gamma in {0.1, 0.5, 1, 3, 5, 10, 30, 50} and tau in [0.15, 0.85]
(step 0.05).{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
The examples below use the Grunfeld (1958) investment data, a classic balanced
panel dataset (N=10 firms, T=20 years) available via {cmd:webuse grunfeld}.

{dlgtab:Setup}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtdescribe}{p_end}

{dlgtab:CIPS(tau) Test}

{pstd}
{bf:Example 1: CIPS(tau) with default quantiles (intercept model)}

{phang2}{cmd:. xtpqroot invest, model(intercept) maxlag(2) reps(1000)}{p_end}

{pstd}
This runs the quantile panel unit root test at the default 9 quantiles
(0.1, 0.2, ..., 0.9) with an intercept-only model. The test reports both
the standard CIPS statistic and CIPS(tau) at each quantile, with Monte
Carlo p-values from 1000 replications. Output includes:

{phang2}
- Data Summary with variable info, panel dimensions, and truncation constants{p_end}
{phang2}
- Panel Unit Root Tests table with CIPS statistic and p-value{p_end}
{phang2}
- CIPS(tau) table with statistic, p-value, significance stars, and decision{p_end}
{phang2}
- Hypotheses and interpretation guide{p_end}
{phang2}
- Footer: *** p<0.01, ** p<0.05, * p<0.10{p_end}
{phang2}
- Source: Yang, Wei & Cai (2022, Econ. Letters); Nazlioglu et al. (2026, NAJEF){p_end}
{phang2}
- Two combined graphs (CIPS(tau) across quantiles + rho(tau) persistence){p_end}

{pstd}
{bf:Example 2: CIPS(tau) at specific quantiles with CD test and individual results}

{phang2}{cmd:. xtpqroot invest, quantile(0.1 0.5 0.9) model(intercept) maxlag(2) reps(1000) cdtest individual}{p_end}

{pstd}
Tests at the 10th, 50th, and 90th percentiles only. The {opt cdtest}
option adds the Pesaran (2021) CD test for cross-sectional dependence
(both OLS-based CD and quantile-based CD(tau) at each quantile).
The {opt individual} option displays panel-specific autoregressive
coefficients rho and their significance, allowing identification of
which firms reject the unit root. A summary line shows how many panels
reject out of N at each quantile.

{pstd}
{bf:Example 3: CIPS(tau) with trend model}

{phang2}{cmd:. xtpqroot invest, quantile(0.1 0.3 0.5 0.7 0.9) model(trend) maxlag(2) reps(1000)}{p_end}

{pstd}
Includes a linear trend in the CADF regression. Use this specification
when the series exhibits trending behavior. The truncation constant K2
changes from 2.16 (intercept) to 2.61 (trend).

{pstd}
{bf:Example 4: Suppress graphs for speed}

{phang2}{cmd:. xtpqroot invest, model(intercept) reps(200) nograph}{p_end}

{dlgtab:tFR Test (Fourier + Sharp Breaks)}

{pstd}
{bf:Example 5: tFR test -- intercept shift (Model A)}

{phang2}{cmd:. xtpqroot invest, fourier model(intercept) maxlag(2) bootreps(2000)}{p_end}

{pstd}
Tests for a unit root allowing for both smooth (Fourier) and sharp (LST)
structural breaks in the intercept. Output includes:

{phang2}
- Data Summary with model type, CSD correction, bootstrap replications{p_end}
{phang2}
- Panel Test Result with tFR statistic, bootstrap p-value, and stars{p_end}
{phang2}
- Bootstrap Critical Values table (1%, 5%, 10%) with reject/fail decision{p_end}
{phang2}
- Individual Panel Results (t_i,fr, k^fr, gamma, tau, Break Date, SIC p){p_end}
{phang2}
- Sharp and Smooth Break Dates table (Table 6 format){p_end}
{phang2}
- Notes explaining how break dates are determined{p_end}
{phang2}
- Hypotheses{p_end}
{phang2}
- Footer: *** p<0.01, ** p<0.05, * p<0.10{p_end}
{phang2}
- Source: Corakci & Omay (2023, Renewable Energy){p_end}
{phang2}
- Two graphs (panel fitted curves + t-statistic bar chart){p_end}

{pstd}
{bf:Example 6: tFR test -- trend model (Model B)}

{phang2}{cmd:. xtpqroot invest, fourier model(trend) maxlag(2) bootreps(2000)}{p_end}

{pstd}
Adds a linear trend to the break model. Appropriate when the series
has a deterministic trend component.

{pstd}
{bf:Example 7: tFR test -- intercept + trend shift (Model C)}

{phang2}{cmd:. xtpqroot invest, fourier model(trendshift) maxlag(2) bootreps(2000)}{p_end}

{pstd}
The most general model, allowing both the intercept and trend slope
to shift at the break point. Use when you suspect the trend growth rate
itself may have changed.

{dlgtab:Complete test suite}

{pstd}
{bf:Example 8: Running all tests on the same dataset}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. set seed 2026}{p_end}
{phang2}{it:* CIPS(tau) -- default quantiles}{p_end}
{phang2}{cmd:. xtpqroot invest, model(intercept) maxlag(2) reps(1000)}{p_end}
{phang2}{it:* CIPS(tau) -- 3 quantiles + CD test + individual}{p_end}
{phang2}{cmd:. xtpqroot invest, quantile(0.1 0.5 0.9) model(intercept) maxlag(2) reps(1000) cdtest individual}{p_end}
{phang2}{it:* CIPS(tau) -- trend model}{p_end}
{phang2}{cmd:. xtpqroot invest, quantile(0.1 0.3 0.5 0.7 0.9) model(trend) maxlag(2) reps(1000)}{p_end}
{phang2}{it:* Fourier -- all three models}{p_end}
{phang2}{cmd:. xtpqroot invest, fourier model(intercept) maxlag(2) bootreps(2000)}{p_end}
{phang2}{cmd:. xtpqroot invest, fourier model(trend) maxlag(2) bootreps(2000)}{p_end}
{phang2}{cmd:. xtpqroot invest, fourier model(trendshift) maxlag(2) bootreps(2000)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtpqroot} stores the following in {bf:r()}:

{pstd}
{bf:Common scalars:}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(N_panels)}}number of cross-sectional units (N){p_end}
{synopt:{cmd:r(T_periods)}}number of time periods (T){p_end}

{pstd}
{bf:Common macros:}

{synopt:{cmd:r(cmd)}}"xtpqroot"{p_end}
{synopt:{cmd:r(varname)}}name of the tested variable{p_end}
{synopt:{cmd:r(panelvar)}}panel variable{p_end}
{synopt:{cmd:r(timevar)}}time variable{p_end}
{synopt:{cmd:r(model)}}"intercept", "trend", or "trendshift"{p_end}

{pstd}
{bf:CIPS(tau) scalars:}

{synopt:{cmd:r(cips)}}CIPS statistic (OLS-based, Pesaran 2007){p_end}
{synopt:{cmd:r(cips_p)}}Monte Carlo p-value for CIPS{p_end}
{synopt:{cmd:r(cipstau_XX)}}CIPS(tau) statistic at quantile 0.XX{p_end}
{synopt:{cmd:r(pval_XX)}}Monte Carlo p-value at quantile 0.XX{p_end}
{synopt:{cmd:r(maxlag)}}lag order used{p_end}
{synopt:{cmd:r(reps)}}number of MC replications{p_end}

{pstd}
{bf:CIPS(tau) matrices:}

{synopt:{cmd:r(cipstau)}}(nq x 3) matrix: tau, CIPS(tau) statistic, p-value{p_end}

{pstd}
{bf:CIPS(tau) macros:}

{synopt:{cmd:r(test)}}"CIPStau"{p_end}

{pstd}
{bf:tFR scalars:}

{synopt:{cmd:r(tfr)}}tFR panel statistic{p_end}
{synopt:{cmd:r(pvalue)}}sieve bootstrap p-value{p_end}
{synopt:{cmd:r(cv01)}}1% bootstrap critical value{p_end}
{synopt:{cmd:r(cv05)}}5% bootstrap critical value{p_end}
{synopt:{cmd:r(cv10)}}10% bootstrap critical value{p_end}
{synopt:{cmd:r(bootreps)}}number of bootstrap replications{p_end}

{pstd}
{bf:tFR matrices:}

{synopt:{cmd:r(ind_results)}}(N x 7) matrix of individual results:{p_end}
{phang3}Columns: t_i,fr | k^fr | gamma | tau | break_date | phi | SIC_lag{p_end}

{pstd}
{bf:tFR macros:}

{synopt:{cmd:r(test)}}"tFR"{p_end}
{synopt:{cmd:r(model_type)}}model label (A, B, or C){p_end}


{marker references}{...}
{title:References}

{phang}
Chang, Y. (2004). Bootstrap unit root tests in panels with cross-sectional dependency.
{it:Journal of Econometrics} 120, 263{c -}293.

{phang}
Corakci, A. and Omay, T. (2023). Is there convergence in renewable energy deployment?
Evidence from a new panel unit root test with smooth and sharp structural breaks.
{it:Renewable Energy} 205, 648{c -}662.

{phang}
Koenker, R. and Xiao, Z. (2004). Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99, 775{c -}787.

{phang}
Nazlioglu, S., Tarakci, D., Karul, C., and Erdem, U. (2026). Inflation shocks:
quantile unit root inference for panel data with cross-correlations. {it:North American
Journal of Economics and Finance} 83, 102592.

{phang}
Pesaran, M.H. (2007). A simple panel unit root test in the presence of cross-section
dependence. {it:Journal of Applied Econometrics} 22, 265{c -}312.

{phang}
Yang, Z., Wei, Z., and Cai, Y. (2022). Quantile unit root inference for panel data
with common shocks. {it:Economics Letters} 219, 110809.


{marker authors}{...}
{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Please cite the original methodological papers when using this command.


{title:Also see}

{psee}
Online: {helpb xtunitroot}, {helpb xtset}, {helpb qreg}
{p_end}
