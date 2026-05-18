{smcl}
{* *! coefconv v1.1.0 — May 2026 — Dr Noman Arshed}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "coefconv_plot" "help coefconv_plot"}{...}
{viewerjumpto "Syntax" "coefconv##syntax"}{...}
{viewerjumpto "Description" "coefconv##description"}{...}
{viewerjumpto "Options" "coefconv##options"}{...}
{viewerjumpto "Families" "coefconv##families"}{...}
{viewerjumpto "Family 8" "coefconv##family8"}{...}
{viewerjumpto "Negative Pratt %" "coefconv##negpratt"}{...}
{viewerjumpto "Examples" "coefconv##examples"}{...}
{viewerjumpto "Stored results" "coefconv##results"}{...}
{viewerjumpto "Limitations" "coefconv##limits"}{...}
{viewerjumpto "Author" "coefconv##author"}{...}
{hline}
help for {hi:coefconv}{right:v1.1.0 — May 2026}
{hline}


{title:Title}

{pstd}
{hi:coefconv} {hline 2} Comprehensive marginal effects from regression slope
coefficients


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:coefconv} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt gr:ate(#)}}growth rate for default ΔX = grate·X̄; default {cmd:0.01}{p_end}
{synopt :{opt quan:tiles(numlist)}}extra percentiles beyond default {cmd:10 25 50 75 90}{p_end}
{synopt :{opt delta(numlist)}}custom ΔX list applied to every predictor{p_end}
{synopt :{opt sav:ing(filename}{cmd:[,}{opt rep:lace}{cmd:])}}save wide results dataset{p_end}
{synopt :{opt notab:le}}suppress display; computation still runs{p_end}
{synopt :{opt for:mat(fmt)}}Stata number format; default {cmd:%12.6f}{p_end}
{synopt :{opt pl:ot}}draw per-IV reference-relative column charts{p_end}
{synopt :{opt gyb:ench(#)}}user-supplied Y growth rate (decimal){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:coefconv} runs after any linear estimation that populates
{cmd:e(b)}, {cmd:e(V)}, {cmd:e(depvar)}, and {cmd:e(sample)} — including
{helpb regress}, {helpb ivregress}, {helpb areg}, {helpb xtreg},
{helpb xtgls}, and {helpb reg3}. For non-linear estimators
({helpb logit}, {helpb probit}, {helpb tobit}, …), a warning is issued
since OLS-style slopes are not marginal effects in those models — use
{helpb margins} instead.


{marker description}{...}
{title:Description}

{pstd}
{cmd:coefconv} computes 30 marginal effect types for every predictor in
the most recently estimated regression model, organised into 8 interpretation
families. All quantities are drawn automatically from Stata's {cmd:e()}
results and restricted to the estimation sample.

{pstd}
A single raw slope β can be summarised in many different ways depending on
the intended audience, the scale of the variables, the role of the predictor
in the model, and the nature of variation in Y itself. Different summaries
can lead to different conclusions about whether the coefficient is "large"
or "small". {cmd:coefconv} computes them side by side so the reader can read
across rather than commit to one summary too early.

{pstd}
The companion command {helpb coefconv_plot} produces three named summary
graphs ({cmd:ccv_std}, {cmd:ccv_pratt}, {cmd:ccv_eff_<varname>}). The
{opt plot} option on {cmd:coefconv} itself adds per-predictor
reference-relative column charts ({cmd:ccv_ref_<varname>}) that compare each
coefficient against six different reference points on a common percentage
axis.


{marker options}{...}
{title:Options}

{phang}
{opt grate(#)} sets the growth rate used to construct the default
discrete-change scenario ΔX = grate·X̄. With the default of 0.01, all
percentage-based effects in Family 8 and the "Growth-Rate ΔX" row in Family 7
represent the effect of a 1% movement in X relative to its mean.

{phang}
{opt quantiles(numlist)} adds further percentiles to Family 6 beyond the
defaults {cmd:10 25 50 75 90}. Values must be integers between 1 and 99.

{phang}
{opt delta(numlist)} appends one or more user-specified ΔX values that are
applied to every predictor. Useful when scenarios are defined in raw units,
e.g. {cmd:delta(500 2000)} for absolute changes.

{phang}
{opt saving(filename}{cmd:[,}{opt replace}{cmd:])} saves a wide results
dataset with one row per predictor and one column per effect, including
Family 8 metrics and observed growth rates. Specify {opt replace} to
overwrite an existing file.

{phang}
{opt notable} suppresses all display output but still computes and stores
every quantity in {cmd:r()}. Use this when calling {cmd:coefconv}
programmatically from another do-file or program.

{phang}
{opt format(fmt)} controls the Stata numeric format used for displayed
values; default {cmd:%12.6f}. Family 8 percentages always display as
{cmd:%12.4f%%} regardless of this option.

{phang}
{opt plot} produces one named column chart per non-factor predictor,
displaying the reference-relative metrics described under
{help coefconv##family8:Family 8} below. Each chart is named
{cmd:ccv_ref_<varname>}. All charts remain open simultaneously and can be
brought forward via {cmd:graph display ccv_ref_<varname>}.

{phang}
{opt gybench(#)} sets a user-supplied Y growth rate (decimal — 0.02 means
2%) that overrides the observed rate from {helpb tsset} or {helpb xtset}.
Useful for cross-sectional data benchmarked against an external reference
(policy target, sectoral CAGR, published forecast). When set, the period
metric uses this rate; growth attribution still requires a panel/time
structure since per-predictor growth rates cannot be hard-coded.


{marker families}{...}
{title:Effect families}

{pstd}
{bf:Family 1 — Raw and Standardised Slopes}

{pmore}
β (raw); β* = β·σX/σY (fully standardised); β·σX (X-standardised);
β/σY (Y-standardised).

{pstd}
{bf:Family 2 — Elasticity and Semi-Elasticity}

{pmore}
ε = β·X̄/Ȳ (elasticity at means); β·X̄ (X-semi-elasticity);
(β/Ȳ)·100 (Y-semi-elasticity).

{pstd}
{bf:Family 3 — Basis-Point and Percentage-Point Effects}

{pmore}
β/10,000; β/100; β·X̄/100.

{pstd}
{bf:Family 4 — Relative and Proportional Effects}

{pmore}
β/Ȳ (proportional ME); (β/Ȳ)·100 (% of mean-Y ME).

{pstd}
{bf:Family 5 — Variance and Importance Measures}

{pmore}
β*² (squared standardised coefficient); β·r(Y,X) (product measure);
β*·r(Y,X) (Pratt numerator); Pratt % of R² (in summary table).

{pstd}
{bf:Family 6 — Quantile Displacements}

{pmore}
For each percentile in {opt quantiles()}, the implied ΔY from moving X from
its median to that percentile.

{pstd}
{bf:Family 7 — Discrete Change Effects}

{pmore}
ΔY for: growth-rate ΔX = grate·X̄; inter-quartile change; full range;
±1·σX; ±2·σX; and any user-supplied {opt delta(numlist)}.

{pstd}
{bf:Family 8 — Reference-Relative Effects} {it:(new in 1.1.0)}

{pmore}
ΔY/σY (% of one Y-SD); ΔY/IQR(Y) (% of Y's middle 50%); ΔY/(Ȳ·g_Y) (% of
one period's typical Y movement); ε·g_X/g_Y (growth attribution). See the
next section for interpretation.


{marker family8}{...}
{title:Family 8 — interpretation in detail}

{pstd}
Family 8 was added to address a recurring problem in applied research: when
β is numerically small, it is not always clear whether the {it:effect} is
small or whether {it:Y itself does not move very much}. A slope of 0.05
means very different things depending on whether Y typically varies by 0.001
or by 5,000.

{pstd}
The first three metrics benchmark the discrete-change effect against
measures of Y's spread or movement:

{phang2}
{bf:ΔY / σY} — effect as a percentage of one standard deviation of Y.

{phang2}
{bf:ΔY / IQR(Y)} — effect as a percentage of Y's middle-50% spread.

{phang2}
{bf:ΔY / (Ȳ · g_Y)} — effect as a percentage of one period's typical
movement in Y, where g_Y is either the observed growth rate from
{helpb tsset}/{helpb xtset} or the user-supplied {opt gybench(#)}.

{pstd}
The fourth metric is the most direct interpretive answer for "is this small
β actually small?":

{phang2}
{bf:ε · g_X / g_Y} — growth attribution: the share of Y's typical growth
explained by X moving at its own typical pace. An elasticity of 0.05 sounds
tiny, but if g_X = 4% and g_Y = 0.4%, the attribution is
(0.05 × 4) / 0.4 = 50% — half of Y's growth.

{pstd}
{bf:Growth-rate definition.} Both g_Y and each g_X are computed as the mean
of |ΔV / V_lag| over the estimation sample, lagged within panel units when
{cmd:xtset} is active. The absolute value makes the metric robust for
oscillating series (REER, capital flows, scope-emission changes) where
signed growth would collapse toward zero.

{pstd}
{bf:Cross-sectional data.} The first two metrics always work. The period
and attribution metrics require either {cmd:tsset}, {cmd:xtset}, or — for
the period denominator only — {opt gybench(#)}. Without any of these, the
corresponding chart bars are omitted and the table cells display as missing.


{marker negpratt}{...}
{title:Note on negative Pratt %}

{pstd}
When the model includes a squared term (e.g. {cmd:c.X##c.X}) or an
interaction, the Pratt decomposition of R² can assign a {bf:negative} share
to one of the components. This is mathematically correct, not a bug in the
package. It happens because the individual term's β* and its zero-order
correlation r(Y, X) have opposite signs, so the product β*·r(Y, X) is
negative. The signed components still sum to R² overall.

{pstd}
{bf:Interpretation.} A negative Pratt component represents a {it:suppression}
contribution relative to its co-occurring terms: X and X² jointly explain Y's
variance, but one of them, taken alone, correlates with Y in the opposite
direction from how it enters the fitted model. It is not "reducing" the
model's explained variance.

{pstd}
{cmd:coefconv} automatically detects negative Pratt components and prints an
explanatory note after the Pratt summary table. In the Family 8 column chart,
the corresponding bar simply extends to the left of zero with the value
clearly labelled.


{marker examples}{...}
{title:Examples}

{pstd}Basic use on cross-sectional data{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv}{p_end}

{pstd}With reference-relative plots{p_end}
{phang2}{cmd:. coefconv, plot}{p_end}
{phang2}{cmd:. graph display ccv_ref_weight}{p_end}

{pstd}User-supplied Y growth benchmark (cross-section + 2% annual reference){p_end}
{phang2}{cmd:. coefconv, plot gybench(0.02)}{p_end}

{pstd}Custom scenarios and additional quantiles{p_end}
{phang2}{cmd:. coefconv, grate(0.05) quantiles(5 95)}{p_end}
{phang2}{cmd:. coefconv, delta(500 2000)}{p_end}

{pstd}Squared term — negative Pratt % detection{p_end}
{phang2}{cmd:. regress price c.mpg##c.mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv}{p_end}

{pstd}Save wide results dataset{p_end}
{phang2}{cmd:. coefconv, saving(coefconv_results, replace) notable}{p_end}

{pstd}Programmatic access to stored results{p_end}
{phang2}{cmd:. coefconv, notable}{p_end}
{phang2}{cmd:. display "Elasticity of mpg:           " r(elas_mpg)}{p_end}
{phang2}{cmd:. display "Pratt % of weight:           " r(pratt_pct_weight)}{p_end}
{phang2}{cmd:. display "Growth attribution (weight): " r(ref_attrib_weight)}{p_end}

{pstd}Panel example — Family 8 fully populated{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtreg invest mvalue kstock, fe}{p_end}
{phang2}{cmd:. coefconv, plot}{p_end}

{pstd}Combining with coefconv_plot's summary graphs{p_end}
{phang2}{cmd:. coefconv_plot}                {it:// ccv_std, ccv_pratt, ccv_eff_*}{p_end}
{phang2}{cmd:. coefconv, plot}               {it:// adds ccv_ref_*}{p_end}
{phang2}{cmd:. graph dir, name}              {it:// all open simultaneously}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:coefconv} is {help return:r-class} and stores the following.

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(r2)}}R-squared{p_end}
{synopt:{cmd:r(ymean)}}mean of Y{p_end}
{synopt:{cmd:r(ysd)}}standard deviation of Y{p_end}
{synopt:{cmd:r(yiqr)}}inter-quartile range of Y{p_end}
{synopt:{cmd:r(pratt_tot)}}sum of Pratt numerators (= R²){p_end}
{synopt:{cmd:r(gY)}}effective Y growth rate used in Family 8{p_end}
{synopt:{cmd:r(gY_obs)}}observed Y growth rate from the data{p_end}
{synopt:{cmd:r(has_time)}}1 if {cmd:tsset}/{cmd:xtset} is active, 0 otherwise{p_end}

{p2col 5 26 30 2: Locals}{p_end}
{synopt:{cmd:r(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}list of predictor names{p_end}
{synopt:{cmd:r(gY_src)}}{cmd:OBSERVED}, {cmd:USER}, or {cmd:n/a}{p_end}

{p2col 5 26 30 2: Per-predictor scalars}{p_end}
{synopt:{cmd:r(b_}{it:varname}{cmd:)}}raw slope coefficient{p_end}
{synopt:{cmd:r(bstd_}{it:varname}{cmd:)}}fully standardised slope (β*){p_end}
{synopt:{cmd:r(elas_}{it:varname}{cmd:)}}point elasticity at means{p_end}
{synopt:{cmd:r(ysemi_}{it:varname}{cmd:)}}Y-semi-elasticity (%){p_end}
{synopt:{cmd:r(pratt_n_}{it:varname}{cmd:)}}Pratt numerator{p_end}
{synopt:{cmd:r(pratt_pct_}{it:varname}{cmd:)}}Pratt % of R² (signed){p_end}
{synopt:{cmd:r(gX_}{it:varname}{cmd:)}}observed X growth rate{p_end}
{synopt:{cmd:r(ref_pctY_}{it:varname}{cmd:)}}Family 8: ΔY / Ȳ (%){p_end}
{synopt:{cmd:r(ref_sd_}{it:varname}{cmd:)}}Family 8: ΔY / σY (%){p_end}
{synopt:{cmd:r(ref_iqr_}{it:varname}{cmd:)}}Family 8: ΔY / IQR(Y) (%){p_end}
{synopt:{cmd:r(ref_period_}{it:varname}{cmd:)}}Family 8: ΔY / (Ȳ·g_Y) (%){p_end}
{synopt:{cmd:r(ref_attrib_}{it:varname}{cmd:)}}Family 8: ε·g_X/g_Y (%){p_end}
{p2colreset}{...}


{marker limits}{...}
{title:Limitations}

{phang}
{bf:1.} Results depend on the estimation sample defined by {cmd:e(sample)}.
Ensure the correct estimation has been run before calling {cmd:coefconv}.

{phang}
{bf:2.} Elasticities and proportional effects are undefined when Ȳ = 0.

{phang}
{bf:3.} Standardised slopes require σX > 0 and σY > 0.

{phang}
{bf:4.} Family 8 temporal metrics (period, attribution) require
{cmd:tsset}/{cmd:xtset}, or {opt gybench()} for the period denominator only.
Growth attribution always requires a time/panel structure.

{phang}
{bf:5.} For variables with many zeros, the growth-rate computation skips
lags that equal zero. If most lags are zero, the resulting g_X is computed
from a thin subset and should be interpreted with care.

{phang}
{bf:6.} Factor variables (e.g. {cmd:i.region}) are skipped in Families 2–8
since they cannot be summarised by a single mean and SD. Their raw β still
appears in Family 1.

{phang}
{bf:7.} For non-linear estimators ({cmd:logit}, {cmd:probit}, {cmd:tobit}),
{cmd:coefconv} reports the OLS-style summaries with a warning; these are
not marginal effects in those models. Use {helpb margins} instead.


{title:Citation}

{pstd}
If you use {cmd:coefconv} in published research, please cite:

{phang2}
Arshed, N. (2026). {it:coefconv: Comprehensive Marginal Effects for Stata.}
Statistical Software Components, Boston College Department of Economics.
{browse "https://ideas.repec.org/c/boc/bocode/"}


{marker author}{...}
{title:Author}

{pstd}
Dr Noman Arshed{break}
Senior Lecturer, Department of Business Analytics{break}
Sunway Business School, Sunway University, Malaysia{break}
{browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}{break}
{browse "https://econistics.com":econistics.com}

{pstd}
Bug reports and suggestions welcome.


{title:Also see}

{psee}
Online: {helpb coefconv_plot}, {helpb regress}, {helpb margins},
{helpb xtreg}, {helpb correlate}
