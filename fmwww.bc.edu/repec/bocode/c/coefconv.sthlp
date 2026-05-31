{smcl}
{* *! coefconv v1.2.0 — May 2026 — Dr Noman Arshed}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "coefconv_plot" "help coefconv_plot"}{...}
{viewerjumpto "Syntax" "coefconv##syntax"}{...}
{viewerjumpto "Description" "coefconv##description"}{...}
{viewerjumpto "Options" "coefconv##options"}{...}
{viewerjumpto "Interpretation guide" "coefconv##guide"}{...}
{viewerjumpto "Family 1" "coefconv##fam1"}{...}
{viewerjumpto "Family 2" "coefconv##fam2"}{...}
{viewerjumpto "Family 3" "coefconv##fam3"}{...}
{viewerjumpto "Family 4" "coefconv##fam4"}{...}
{viewerjumpto "Family 5" "coefconv##fam5"}{...}
{viewerjumpto "Family 6" "coefconv##fam6"}{...}
{viewerjumpto "Family 7" "coefconv##fam7"}{...}
{viewerjumpto "Family 8" "coefconv##fam8"}{...}
{viewerjumpto "Dominance / Shapley" "coefconv##dominance"}{...}
{viewerjumpto "Negative Pratt %" "coefconv##negpratt"}{...}
{viewerjumpto "Visualization" "coefconv##plots"}{...}
{viewerjumpto "Stored results" "coefconv##results"}{...}
{viewerjumpto "Examples" "coefconv##examples"}{...}
{viewerjumpto "Limitations" "coefconv##limits"}{...}
{viewerjumpto "Author" "coefconv##author"}{...}
{hline}
help for {hi:coefconv}{right:v1.2.0 — May 2026}
{hline}


{title:Title}

{pstd}
{hi:coefconv} {hline 2} Comprehensive marginal effects from regression slope
coefficients


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:coefconv} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt gr:ate(#)}}growth rate for default ΔX = grate·X̄; default {cmd:0.01} (1%){p_end}
{synopt :{opt quan:tiles(numlist)}}extra percentiles beyond default {cmd:10 25 50 75 90}{p_end}
{synopt :{opt delta(numlist)}}custom ΔX list applied to every predictor{p_end}
{synopt :{opt sav:ing(filename}{cmd:[,}{opt rep:lace}{cmd:])}}save wide results dataset (one row per predictor){p_end}
{synopt :{opt notab:le}}suppress display; computation still runs{p_end}
{synopt :{opt for:mat(fmt)}}Stata number format; default {cmd:%12.6f}{p_end}
{synopt :{opt pl:ot}}draw per-IV reference-relative column charts (Family 8){p_end}
{synopt :{opt gyb:ench(#)}}user-supplied Y growth rate (decimal){p_end}
{synopt :{opt dom:inance}}add general-dominance / Shapley R² decomposition{p_end}
{synopt :{opt maxd:om(#)}}maximum predictors for dominance; default {cmd:14}{p_end}
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
{cmd:coefconv} computes 30 marginal effect types for every predictor in the
most recently estimated regression model, organised into 8 interpretation
families, and optionally a general-dominance / Shapley decomposition of R².
All quantities are drawn automatically from Stata's {cmd:e()} results and
restricted to the estimation sample. No separate data-preparation step is
required.

{pstd}
A single raw slope β can be summarised in many different ways depending on
the intended audience, the scale of the variables, the role of the predictor
in the model, and the nature of variation in Y itself. Different summaries
can lead to different conclusions about whether the coefficient is "large"
or "small". {cmd:coefconv} computes them side by side so the reader can read
across rather than commit to one summary too early.

{pstd}
This help file documents every effect in full, with a worked example, a
plain-language template, and guidance on when each measure is appropriate.
The guide assumes no prior exposure to earlier versions of the command.

{pstd}
The companion command {helpb coefconv_plot} produces three named summary
graphs ({cmd:ccv_std}, {cmd:ccv_pratt}, {cmd:ccv_eff_<varname>}). The
{opt plot} option on {cmd:coefconv} itself adds per-predictor
reference-relative column charts ({cmd:ccv_ref_<varname>}). See
{help coefconv##plots:Visualization} below.


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
Family 8 metrics, observed growth rates, and (if requested) the dominance
columns. Specify {opt replace} to overwrite an existing file.

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
{help coefconv##fam8:Family 8}. Each chart is named {cmd:ccv_ref_<varname>}.
All charts remain open simultaneously and can be brought forward via
{cmd:graph display ccv_ref_<varname>}.

{phang}
{opt gybench(#)} sets a user-supplied Y growth rate (decimal — 0.02 means
2%) that overrides the observed rate from {helpb tsset} or {helpb xtset}.
Useful for cross-sectional data benchmarked against an external reference
(policy target, sectoral CAGR, published forecast). When set, the period
metric uses this rate; growth attribution still requires a panel/time
structure since per-predictor growth rates cannot be hard-coded.

{phang}
{opt dominance} adds a general-dominance / Shapley decomposition of R²
alongside the Pratt summary. See {help coefconv##dominance:General dominance}
below. The computation cost grows as 2^k in the number of continuous
predictors k.

{phang}
{opt maxdom(#)} caps the number of continuous predictors for which the
dominance decomposition is attempted; default {cmd:14} (2^14 = 16,384 subset
fits). If the model has more continuous predictors than this, the dominance
step is skipped with a message. Raise the cap only if you accept the runtime.


{marker guide}{...}
{title:Interpretation guide}

{pstd}
All examples below use a single illustrative wage regression to keep numbers
consistent across all effect types:

{pmore}
{cmd:. regress hourly_wage education experience}

{pmore}
Model statistics: N = 500,  R² = 0.42,  RMSE = 4.58
{p_end}
{pmore}
Ȳ = 18.00  (mean hourly wage, $),  σY = 6.00,  IQR(Y) = 8.00
{p_end}

{pmore}
Results for predictor {bf:education} (years of schooling):
{p_end}
{pmore2}
β = 1.20  |  X̄ = 14.00  |  σX = 3.00  |  r(Y,X) = 0.55
{p_end}
{pmore2}
Quantiles: p10 = 10, p25 = 12, p50 = 14, p75 = 16, p90 = 18
{p_end}


{marker fam1}{...}
{dlgtab:Family 1 — Raw & Standardized Slopes}

{pstd}
These four measures all express the slope on different scales. They answer:
"how big is this effect, and how does it compare across predictors measured
in different units?"

{p2colset 5 30 32 2}
{p2col:{bf:1. Raw Slope (β)}}Formula: β{p_end}
{p2col:}{it:Template}: A 1-unit increase in X is associated with a β-unit change in Y.{p_end}
{p2col:}{it:Example}: β = 1.20  →  "One additional year of education is associated with a
$1.20/hour increase in wages, holding other variables constant."{p_end}
{p2col:}{it:When to use}: Your default go-to. Meaningful whenever X and Y are in
interpretable, natural units (years, dollars, kilograms, etc.).{p_end}

{p2col:{bf:2. Fully Standardized Slope (β*)}}Formula: β × (σX / σY){p_end}
{p2col:}{it:Template}: A 1-SD increase in X is associated with a β*-SD change in Y.{p_end}
{p2col:}{it:Example}: β* = 1.20 × (3.00/6.00) = 0.60  →  "A 1-SD increase in education
(3 additional years) is associated with a 0.60-SD increase in wages
($3.60/hour). A β* of 0.60 is considered a large effect."{p_end}
{p2col:}{it:When to use}: Comparing the relative importance of predictors measured on
different scales. Directly comparable across all X variables in the model.{p_end}

{p2col:{bf:3. X-Standardized Slope}}Formula: β × σX{p_end}
{p2col:}{it:Template}: A 1-SD increase in X is associated with a (β×σX)-unit change in Y.
Y remains in its original units.{p_end}
{p2col:}{it:Example}: β×σX = 1.20 × 3.00 = 3.60  →  "A 1-SD increase in education
(3 additional years) is associated with $3.60/hour higher wages."{p_end}
{p2col:}{it:When to use}: When you want the practical magnitude of a 1-SD shift in X
expressed in the natural units of Y (dollars, not standard deviations).{p_end}

{p2col:{bf:4. Y-Standardized Slope}}Formula: β / σY{p_end}
{p2col:}{it:Template}: A 1-unit increase in X is associated with a (β/σY)-SD change in Y.
X remains in its original units.{p_end}
{p2col:}{it:Example}: β/σY = 1.20/6.00 = 0.20  →  "Each additional year of education is
associated with wages increasing by 0.20 standard deviations ($1.20)."{p_end}
{p2col:}{it:When to use}: When X has a natural unit (e.g., one year of school) but you want
to express the outcome on a standardized scale for context.{p_end}


{marker fam2}{...}
{dlgtab:Family 2 — Elasticity & Semi-Elasticity}

{pstd}
These measures express effects as percentage changes, making them scale-free.
They are the workhorses of economic and policy analysis.

{p2col:{bf:5. Point Elasticity}}Formula: β × (X̄ / Ȳ){p_end}
{p2col:}{it:Template}: A 1% increase in X is associated with an ε% change in Y
(evaluated at the means of X and Y).{p_end}
{p2col:}{it:Example}: ε = 1.20 × (14.00/18.00) = 0.933  →  "A 1% increase in
education from its mean (0.14 additional years) is associated with a
0.933% increase in wages ($0.168/hour). Since ε < 1, education is an
inelastic determinant of wages at the means."{p_end}
{p2col:}{it:When to use}: When both X and Y are continuous positive variables and you
want a unit-free effect. Standard in demand analysis, health, and labor
economics. Note: this is a {it:point} elasticity evaluated at the means,
not an arc elasticity.{p_end}

{p2col:{bf:6. X-Semi-Elasticity}}Formula: β × X̄{p_end}
{p2col:}{it:Template}: The displayed value divided by 100 gives ΔY (in Y-units) for a
1% increase in X. Equivalently: ΔY per 100% proportional change in X.{p_end}
{p2col:}{it:Example}: β×X̄ = 1.20 × 14.00 = 16.80  →  Dividing by 100: "A 1% increase
in education from its mean (0.14 additional years) is associated with
$0.168/hour higher wages. A 10% increase would yield $1.68/hour."{p_end}
{p2col:}{it:When to use}: When X could be expressed in log form (continuous, positive).
Arises naturally in log-linear models. Useful when you want to report
the dollar effect of a percentage change in an input.{p_end}
{p2col:}{it:Note}: This is {it:dY/d(lnX)} evaluated at X̄. To get ΔY for a 1% ΔX,
divide the displayed value by 100.{p_end}

{p2col:{bf:7. Y-Semi-Elasticity (%)}}Formula: (β / Ȳ) × 100{p_end}
{p2col:}{it:Template}: A 1-unit increase in X is associated with a (β/Ȳ×100)%
change in Y relative to its mean.{p_end}
{p2col:}{it:Example}: (1.20/18.00)×100 = 6.667  →  "Each additional year of education
is associated with wages that are approximately 6.67% of the mean wage
($1.20) higher. Equivalently, wages increase by about 6.67 percentage
points relative to the average wage of $18.00."{p_end}
{p2col:}{it:When to use}: When Y is continuous and you want to interpret a unit change
in X as a percentage of the average outcome. Common when Y is a level
(income, GDP) and you want a rate interpretation. Arises naturally in
linear-log models.{p_end}


{marker fam3}{...}
{dlgtab:Family 3 — Basis-Point & Percentage-Point Effects}

{pstd}
These are rescaled versions of β for when X is expressed in rates,
proportions, or financial percentages. Essential in finance, macroeconomics,
and public health where the natural unit of X is a percentage or rate.

{p2col:{bf:8. Basis-Point Effect}}Formula: β / 10,000{p_end}
{p2col:}{it:Template}: A 1-basis-point increase in X (0.01 percentage points) is
associated with a (β/10000)-unit change in Y.{p_end}
{p2col:}{it:Example}: 1.20/10000 = 0.000120  →  If X were an interest rate in decimal
form: "A 1-basis-point rise in the rate (0.01%) is associated with a
$0.000120/hour change in wages." Most meaningful when β is large (e.g.,
β = 500 on an interest rate → 500/10000 = $0.05 per bp).{p_end}
{p2col:}{it:When to use}: X is a financial rate or yield (interest rate, bond spread,
return) measured in decimal form. A standard quoting convention in
fixed income and central banking.{p_end}

{p2col:{bf:9. Percentage-Point Effect}}Formula: β / 100{p_end}
{p2col:}{it:Template}: A 1-percentage-point increase in X is associated with a
(β/100)-unit change in Y.{p_end}
{p2col:}{it:Example}: 1.20/100 = 0.0120  →  If education were measured as a percentage
(e.g., % of workforce with a degree): "A 1-percentage-point increase is
associated with $0.012/hour higher wages." More relevant for a variable
like unemployment rate (β = 200 → 200/100 = $2.00 per ppt).{p_end}
{p2col:}{it:When to use}: X is an index, rate, or share measured as a decimal (e.g.,
0.05 = 5%). Rescaling makes the effect interpretable in percentage-point
terms. Common with unemployment rate, inflation, tax rates.{p_end}

{p2col:{bf:10. Per-1%-of-X Effect}}Formula: β × (X̄ / 100){p_end}
{p2col:}{it:Template}: A 1% increase in X from its mean (a change of X̄/100 units)
is associated with a (β×X̄/100)-unit change in Y.{p_end}
{p2col:}{it:Example}: 1.20 × (14.00/100) = 0.168  →  "A 1% increase in education
from its mean (0.14 additional years) is associated with $0.168/hour
higher wages." This is a more meaningful "small change" benchmark than
an arbitrary 1-unit shift when X̄ >> 1.{p_end}
{p2col:}{it:When to use}: Whenever a 1-unit change in X is large relative to the
actual distribution (e.g., income in thousands, population in millions).
The "per 1% of mean" framing gives a naturally small, realistic shift.{p_end}


{marker fam4}{...}
{dlgtab:Family 4 — Relative & Proportional Effects}

{pstd}
These express the effect relative to the mean of Y, answering: "how big
is this effect as a fraction of the typical outcome?"

{p2col:{bf:11. Proportional Marginal Effect}}Formula: β / Ȳ{p_end}
{p2col:}{it:Template}: A 1-unit increase in X is associated with a (β/Ȳ) proportional
change in Y relative to its mean.{p_end}
{p2col:}{it:Example}: 1.20/18.00 = 0.0667  →  "Each additional year of education is
associated with wages increasing by 0.0667 of the mean wage — that is,
by 1/15th of average wages, or $1.20 per $18 average."{p_end}
{p2col:}{it:When to use}: When you want to benchmark the raw effect against the typical
level of Y. Useful for comparing effects across different outcome
variables (e.g., wages vs. health scores) without standardizing X.{p_end}

{p2col:{bf:12. % of Mean-Y Marginal Effect}}Formula: (β / Ȳ) × 100{p_end}
{p2col:}{it:Template}: A 1-unit increase in X is associated with Y changing by
(β/Ȳ×100) percent of the mean of Y.{p_end}
{p2col:}{it:Example}: (1.20/18.00)×100 = 6.667  →  "Each additional year of education
is associated with wages increasing by 6.67% of the average wage.
At a mean wage of $18.00, this corresponds to $1.20/hour."{p_end}
{p2col:}{it:When to use}: A percentage version of the proportional ME above — easier
to communicate to non-technical audiences. Answers "what fraction of
a typical outcome does this effect represent?"{p_end}


{marker fam5}{...}
{dlgtab:Family 5 — Variance & Importance Measures}

{pstd}
These decompose the model's R² to quantify each predictor's contribution
to explained variance. They answer: "which predictor matters most?"
A more rigorous, correlation-robust decomposition is available via the
{opt dominance} option; see {help coefconv##dominance:below}.

{p2col:{bf:13. Squared Std. Coef. (β*²)}}Formula: (β × σX/σY)²{p_end}
{p2col:}{it:Template}: β*² approximates the proportion of Y's variance uniquely
attributable to X (exact only if all predictors are uncorrelated).{p_end}
{p2col:}{it:Example}: β*² = 0.60² = 0.36  →  "Under orthogonality, education would
account for approximately 36% of the variance in wages. In practice,
with correlated predictors, this overstates unique contribution."{p_end}
{p2col:}{it:When to use}: A quick, intuitive importance metric. Interpret cautiously
with correlated predictors — use Pratt's or the dominance measure instead.{p_end}

{p2col:{bf:14. Product Measure (β × r_XY)}}Formula: β × r(Y, X){p_end}
{p2col:}{it:Template}: The product of the unstandardized slope and zero-order
correlation. Sums to R² across all predictors (unstandardized form
of Pratt).{p_end}
{p2col:}{it:Example}: 1.20 × 0.55 = 0.660  →  Raw contribution to explained variance.
Divide by Σ(β × r) across all predictors to get the share of R².
Positive values indicate productive predictors; negative values
indicate suppressors.{p_end}
{p2col:}{it:When to use}: When raw (unstandardized) Pratt decomposition is preferred,
or to check for suppressor variables (negative product with positive R²).{p_end}

{p2col:{bf:15. Pratt Numerator (β* × r_XY)}}Formula: β* × r(Y, X){p_end}
{p2col:}{it:Template}: X's standardized contribution to R². The Pratt %
of R² (shown in the summary table) = this value divided by Σ(β*×r).{p_end}
{p2col:}{it:Example}: 0.60 × 0.55 = 0.330  →  If Σ(β*×r) = 0.42 (= R²),
then education's Pratt % = 0.330/0.420 = 78.6% of explained variance.
"Education accounts for 78.6% of the variance explained by the model."{p_end}
{p2col:}{it:Note}: Pratt indices sum to exactly 100% of R² across all predictors.
A negative Pratt index identifies a {it:suppressor variable}. See the
{help coefconv##negpratt:note on negative Pratt %}.{p_end}


{marker fam6}{...}
{dlgtab:Family 6 — Discrete ΔY: Median to Each Quantile}

{pstd}
For a linear model the slope β is constant, so "ME at a point" is always β.
Instead, Family 6 answers a richer question: {it:if X were at a specific quantile
rather than at the median, how different would Y be?}  This maps the slope
onto realistic distributional distances.

{p2col:{bf:16–20. Quantile Displacement Effects}}Formula: β × (X_pq − X_p50){p_end}
{p2col:}{it:Template}: If X were at its p{it:q} quantile instead of its median,
Y would be (β × ΔX) units different.{p_end}
{p2col:}{it:Example (p50 → p25)}: ΔX = 12 − 14 = −2.00,  ΔY = 1.20 × (−2) = −2.40
→  "Workers at the 25th percentile of education (12 years) earn $2.40/hour
less than workers at the median (14 years), all else equal."{p_end}
{p2col:}{it:Example (p50 → p75)}: ΔX = 16 − 14 = +2.00,  ΔY = 1.20 × 2 = +2.40
→  "Workers at the 75th percentile of education (16 years) earn $2.40/hour
more than workers at the median."{p_end}
{p2col:}{it:When to use}: Policy scenarios where you want to express effects in terms
of realistic population movements (e.g., "what would it mean to bring
low-education workers up to the median?"). More grounded than abstract
1-unit or 1-SD changes. Add more percentiles with {opt quantiles()}.{p_end}


{marker fam7}{...}
{dlgtab:Family 7 — Discrete Change Effects}

{pstd}
These apply specific ΔX values to β to get concrete predicted changes in Y.
They answer: "what does this effect mean for a realistic policy-relevant
shift in X?"

{p2col:{bf:21. Growth-Rate ΔX Effect}}Formula: β × (grate × X̄){p_end}
{p2col:}{it:Template}: If X grew by grate% from its mean, Y would change by
β × (grate × X̄) units. Default grate = 1%.{p_end}
{p2col:}{it:Example}: ΔX = 0.01 × 14.00 = 0.14,  ΔY = 1.20 × 0.14 = 0.168
→  "A 1% growth in education from its mean (0.14 additional years)
is associated with $0.168/hour higher wages. Use {cmd:grate(0.10)}
to model a 10% expansion."{p_end}
{p2col:}{it:When to use}: Policy simulations expressed as percentage expansions of X
(e.g., a 5% increase in R&D spending, a 2% reduction in interest rates).{p_end}

{p2col:{bf:22. IQR Effect}}Formula: β × (X_p75 − X_p25){p_end}
{p2col:}{it:Template}: Moving X from its 25th to 75th percentile (across the middle
50% of the distribution) changes Y by β × IQR units.{p_end}
{p2col:}{it:Example}: IQR = 16 − 12 = 4.00,  ΔY = 1.20 × 4.00 = 4.80
→  "Moving from the 25th to 75th percentile of education (from 12
to 16 years) is associated with $4.80/hour higher wages — a difference
of about 27% of the mean wage."{p_end}
{p2col:}{it:When to use}: One of the most practically meaningful effect sizes.
The IQR represents the spread of the "typical" population and is
robust to outliers. Well-suited for policy communication.{p_end}

{p2col:{bf:23. Full-Range Effect}}Formula: β × (X_max − X_min){p_end}
{p2col:}{it:Template}: Moving X from its minimum to maximum observed value changes
Y by β × (X_max − X_min) units.{p_end}
{p2col:}{it:Example}: Range = 20 − 8 = 12.00,  ΔY = 1.20 × 12.00 = 14.40
→  "Comparing workers with the highest possible education (20 years)
to those with the least (8 years), the model predicts a $14.40/hour
wage difference — 2.4 times the mean wage."{p_end}
{p2col:}{it:When to use}: To understand the maximum theoretically possible effect
within the observed data. Sensitive to extreme outliers in X.{p_end}

{p2col:{bf:24. ±1 SD Effect}}Formula: β × σX{p_end}
{p2col:}{it:Template}: A one-standard-deviation shift in X changes Y by β×σX units.
(Same as the X-Standardized slope in Family 1.){p_end}
{p2col:}{it:Example}: ΔX = 3.00,  ΔY = 1.20 × 3.00 = 3.60
→  "A one-standard-deviation increase in education (3 additional years)
is associated with $3.60/hour higher wages. Moving ±1 SD from the mean
spans roughly the 16th to 84th percentile of education."{p_end}
{p2col:}{it:When to use}: The most common effect-size benchmark in social science.
Comparable across predictors and familiar to most researchers.{p_end}

{p2col:{bf:25. ±2 SD Effect}}Formula: β × (2 × σX){p_end}
{p2col:}{it:Template}: A two-standard-deviation shift in X changes Y by β×2σX units.
Spans approximately the 2nd to 98th percentile of a normal distribution.{p_end}
{p2col:}{it:Example}: ΔX = 6.00,  ΔY = 1.20 × 6.00 = 7.20
→  "Comparing workers two standard deviations above and below the
education mean is associated with a $7.20/hour wage difference —
a shift covering approximately 95% of the population."{p_end}
{p2col:}{it:When to use}: When you want to describe the effect across a near-complete
range of realistic X values. Common in psychological and health research
following Gelman & Hill's recommendation to use 2-SD scaling.{p_end}

{p2col:{bf:26. Custom ΔX Effects (delta() option)}}Formula: β × ΔX_user{p_end}
{p2col:}{it:Template}: Each value supplied in {opt delta()} is treated as a specific
ΔX; the corresponding ΔY = β × ΔX is displayed for every predictor.{p_end}
{p2col:}{it:Example}: {cmd:coefconv, delta(2 5)}  →  For education:
ΔX = 2: ΔY = 1.20×2 = 2.40  →  "Two extra years of school: +$2.40/hour"
ΔX = 5: ΔY = 1.20×5 = 6.00  →  "Five extra years of school: +$6.00/hour"{p_end}
{p2col:}{it:When to use}: Policy simulations with a specific, externally defined
change (e.g., a $1000 subsidy, a 3-point rate cut). Cuts through all
standardization and answers "what happens if we change X by exactly this much?"{p_end}


{marker fam8}{...}
{dlgtab:Family 8 — Reference-Relative Effects (new in 1.1.0)}

{pstd}
Family 8 addresses a recurring problem in applied research: when β is
numerically small, it is not always clear whether the {it:effect} is small
or whether {it:Y itself does not move very much}. A slope of 0.05 means very
different things depending on whether Y typically varies by 0.001 or by 5,000.
All five metrics use the discrete-change scenario ΔY = β × (grate × X̄) — the
same quantity as effect 21 — and express it relative to a feature of Y.

{p2col:{bf:27. ΔY / Ȳ  (% of Y-mean)}}Formula: (β·grate·X̄ / Ȳ) × 100{p_end}
{p2col:}{it:Template}: Under a grate% movement in X, Y changes by this percentage
of its own mean.{p_end}
{p2col:}{it:Example}: ΔY = 1.20 × 0.14 = 0.168; (0.168/18.00)×100 = 0.933%
→  "A 1% rise in education shifts wages by 0.93% of the average wage."{p_end}
{p2col:}{it:When to use}: A quick scale check — is the scenario effect even a
meaningful fraction of the typical outcome level?{p_end}

{p2col:{bf:28. ΔY / σY  (% of one Y-SD)}}Formula: (β·grate·X̄ / σY) × 100{p_end}
{p2col:}{it:Template}: The scenario effect as a percentage of one standard deviation
of Y.{p_end}
{p2col:}{it:Example}: (0.168/6.00)×100 = 2.80%
→  "The 1%-education scenario moves wages by 2.8% of a wage standard
deviation." A movement well under one σY is small in distributional terms.{p_end}
{p2col:}{it:When to use}: When you want an effect size benchmarked against the spread
of Y rather than its level — closest in spirit to a standardized effect.{p_end}

{p2col:{bf:29. ΔY / IQR(Y)  (% of Y's middle 50%)}}Formula: (β·grate·X̄ / IQR_Y) × 100{p_end}
{p2col:}{it:Template}: The scenario effect as a percentage of Y's inter-quartile range.{p_end}
{p2col:}{it:Example}: (0.168/8.00)×100 = 2.10%
→  "The scenario moves wages by 2.1% of the gap between a typical
below-median and above-median worker."{p_end}
{p2col:}{it:When to use}: A robust alternative to ΔY/σY when Y is skewed or has
outliers; the IQR is unaffected by extreme values.{p_end}

{p2col:{bf:30. ΔY / (Ȳ · g_Y)  (% of one period's typical ΔY)}}Formula: (β·grate·X̄) / (Ȳ·g_Y) × 100{p_end}
{p2col:}{it:Template}: The scenario effect as a percentage of how much Y typically
moves in one period, where g_Y is Y's observed growth rate (from
{helpb tsset}/{helpb xtset}) or the user-supplied {opt gybench(#)}.{p_end}
{p2col:}{it:Example}: If g_Y = 0.02 (2% per period) and Ȳ = 18.00, one period's
typical movement is 0.36; (0.168/0.36)×100 = 46.7%
→  "The 1%-education scenario equals almost half of a typical period's
wage movement."{p_end}
{p2col:}{it:When to use}: Time-series/panel settings where you want the effect framed
against the natural pace of change in Y. Requires a time structure or
{opt gybench()}.{p_end}

{p2col:{bf:30b. ε · g_X / g_Y  (growth attribution)}}Formula: (β·X̄/Ȳ) × g_X / g_Y × 100{p_end}
{p2col:}{it:Template}: The share of Y's typical growth explained by X moving at its
own typical pace. This is the most direct answer to "is this small β
actually small?"{p_end}
{p2col:}{it:Example}: An elasticity of 0.05 sounds tiny, but if g_X = 4% and
g_Y = 0.4%, the attribution is (0.05 × 4)/0.4 = 50% — half of Y's growth.{p_end}
{p2col:}{it:When to use}: Panel/time-series settings. Each g_X and g_Y is computed as
the mean of |ΔV / V_lag| over the estimation sample, lagged within panel
units. The absolute value keeps the metric robust for oscillating series
(REER, capital flows, emission changes) where signed growth collapses to
zero. Requires {helpb tsset}/{helpb xtset}.{p_end}

{pstd}
{bf:Cross-sectional data.} Effects 27–29 always work. The period metric (30)
and the attribution metric (30b) require {helpb tsset}, {helpb xtset}, or —
for the period denominator only — {opt gybench(#)}. Without these, the
corresponding cells display as missing and the chart bars are omitted.


{marker dominance}{...}
{title:General dominance / Shapley importance (option {bf:dominance})}

{pstd}
With {opt dominance}, {cmd:coefconv} adds a second relative-importance table
that complements Pratt. For each continuous predictor it reports the
{bf:general dominance weight} (Budescu 1993), which is identical to the
{bf:LMG} measure (Lindeman, Merenda & Gold 1980) and to the {bf:Shapley}
regression value: each predictor's average marginal contribution to R²,
taken over all possible orderings (subsets) of the predictors.

{pstd}
Formally, the general dominance weight of predictor i is the average, over
every subset S of the {it:other} predictors, of the gain in R² obtained by
adding i to S — that is, R²(S + i) − R²(S) — with Shapley weights
w(s) = s!·(k−1−s)! / k!, where s is the size of S and k the number of
predictors. Each subset R² is obtained from the (Y, X) correlation matrix as
R²(S) = r_YS′ · R_SS⁻¹ · r_YS. {cmd:coefconv} computes this natively in Mata
directly from the correlation matrix it already builds — no model is
re-estimated, {cmd:e()} is untouched, and no external package is required.

{pstd}
{bf:Why use it alongside Pratt.}

{phang2}
{bf:Non-negative.} Unlike Pratt's β*·r — which can turn negative for
suppressors or for the components of a squared/interaction term — general
dominance weights are always ≥ 0.

{phang2}
{bf:Sums to R².} The weights add up exactly to the OLS R² implied by the
correlation matrix, so each predictor's share of R² is in [0, 100%].

{phang2}
{bf:Correlation-robust.} Because it averages over all subsets, the
decomposition does not over-credit whichever correlated predictor happens to
enter "first". A large gap between a predictor's Pratt % and its dominance %
is a useful flag that the Pratt split is being distorted by collinearity.

{pstd}
{bf:Cost and scope.} The computation evaluates 2^k subset R²'s, so it grows
exponentially in the number of continuous predictors k. The {opt maxdom(#)}
option caps k (default 14); above the cap the step is skipped with a message.
Factor/interaction terms are excluded from the decomposition (they have no
single mean/SD), exactly as for Pratt. The denominator is the OLS R² implied
by the correlation matrix; for non-OLS models (IV, FE) this is an
OLS-flavoured approximation, the same caveat that applies to Pratt.


{marker negpratt}{...}
{title:Note on negative Pratt %}

{pstd}
When the model includes a squared term (e.g. {cmd:c.X##c.X}) or an
interaction, the Pratt decomposition of R² can assign a {bf:negative} share
to one of the components. This is mathematically correct, not a bug. It
happens because the individual term's β* and its zero-order correlation
r(Y, X) have opposite signs, so the product β*·r(Y, X) is negative. The
signed components still sum to R² overall.

{pstd}
{bf:Interpretation.} A negative Pratt component represents a {it:suppression}
contribution relative to its co-occurring terms: X and X² jointly explain Y's
variance, but one of them, taken alone, correlates with Y in the opposite
direction from how it enters the fitted model. It is not "reducing" the
model's explained variance, and the variable should not be dropped on this
basis. {cmd:coefconv} detects negative Pratt components automatically and
prints an explanatory note after the Pratt table; the general-dominance
weights (option {opt dominance}) provide a non-negative alternative for the
same model.


{marker plots}{...}
{title:Visualization}

{pstd}
Two routes to graphs, which can be used together:

{pstd}
{bf:1. The {opt plot} option on {cmd:coefconv}} draws one horizontal column
chart per non-factor predictor, named {cmd:ccv_ref_<varname>}, showing the
Family 8 reference-relative metrics (and the Pratt % of R²) on a common
percentage axis with sign preserved. This is the quickest way to see, per
predictor, how the scenario effect compares against every Y reference point
at once.

{pstd}
{bf:2. The companion command {helpb coefconv_plot}} produces three named
summary graphs (it calls {cmd:coefconv} internally, so no prior call is
needed):

{p2colset 7 26 28 2}
{p2col:{cmd:ccv_std}}standardized-slope forest plot: β* with confidence
intervals and Cohen (1988) small/medium/large benchmark lines; navy =
significant, gray = not.{p_end}
{p2col:{cmd:ccv_pratt}}Pratt relative-importance bar chart: each predictor's
% of R², sorted; navy = productive, cranberry = suppressor.{p_end}
{p2col:{cmd:ccv_eff_<varname>}}discrete-effect ladder: nine ΔY scenarios
(growth, ±1/±2 SD, IQR, full range, p50→p10/p25/p75/p90) in Y-units, one
graph per predictor, sorted by |ΔY|.{p_end}

{pstd}
All graphs are assigned unique {cmd:name()}s so they remain open
simultaneously; type {cmd:graph dir} to list them and
{cmd:graph display} {it:name} to bring one forward. See
{helpb coefconv_plot} for the full options ({opt level()}, {opt scheme()},
{opt saving()}, {opt nostd}, {opt nopratt}, {opt noeffects}).


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:coefconv} is {help return:r-class} and stores the following.

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(r2)}}R-squared{p_end}
{synopt:{cmd:r(ymean)}}mean of Y{p_end}
{synopt:{cmd:r(ysd)}}standard deviation of Y{p_end}
{synopt:{cmd:r(yiqr)}}inter-quartile range of Y{p_end}
{synopt:{cmd:r(pratt_tot)}}sum of Pratt numerators (= R²){p_end}
{synopt:{cmd:r(gY)}}effective Y growth rate used in Family 8{p_end}
{synopt:{cmd:r(gY_obs)}}observed Y growth rate from the data{p_end}
{synopt:{cmd:r(has_time)}}1 if {cmd:tsset}/{cmd:xtset} is active, 0 otherwise{p_end}
{synopt:{cmd:r(dom_r2)}}OLS R² used as the dominance denominator (if {opt dominance}){p_end}

{p2col 5 28 32 2: Locals}{p_end}
{synopt:{cmd:r(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}list of predictor names{p_end}
{synopt:{cmd:r(gY_src)}}{cmd:OBSERVED}, {cmd:USER}, or {cmd:n/a}{p_end}

{p2col 5 28 32 2: Per-predictor scalars}{p_end}
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
{synopt:{cmd:r(dom_raw_}{it:varname}{cmd:)}}general-dominance raw weight (if {opt dominance}){p_end}
{synopt:{cmd:r(dom_pct_}{it:varname}{cmd:)}}general-dominance % of R² (if {opt dominance}){p_end}
{p2colreset}{...}

{pstd}
With {opt saving()} the wide dataset adds one row per predictor and includes
columns for every effect family, the observed growth rates ({cmd:gX_v}), and
— when {opt dominance} is requested — {cmd:dom_raw} and {cmd:dom_pct}.


{marker examples}{...}
{title:Examples}

{pstd}Basic use on cross-sectional data{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv}{p_end}

{pstd}Add the general-dominance / Shapley importance table{p_end}
{phang2}{cmd:. coefconv, dominance}{p_end}

{pstd}With reference-relative plots and dominance{p_end}
{phang2}{cmd:. coefconv, plot dominance}{p_end}
{phang2}{cmd:. graph display ccv_ref_weight}{p_end}

{pstd}Companion summary graphs (forest, Pratt, per-variable ladders){p_end}
{phang2}{cmd:. coefconv_plot}{p_end}

{pstd}User-supplied Y growth benchmark (cross-section + 2% annual reference){p_end}
{phang2}{cmd:. coefconv, plot gybench(0.02)}{p_end}

{pstd}Custom scenarios and additional quantiles{p_end}
{phang2}{cmd:. coefconv, grate(0.05) quantiles(5 95)}{p_end}
{phang2}{cmd:. coefconv, delta(500 2000)}{p_end}

{pstd}Squared term — negative Pratt %, with dominance as the non-negative check{p_end}
{phang2}{cmd:. regress price c.mpg##c.mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv, dominance}{p_end}

{pstd}Save wide results dataset (includes dominance columns){p_end}
{phang2}{cmd:. coefconv, dominance saving(coefconv_results, replace) notable}{p_end}

{pstd}Programmatic access to stored results{p_end}
{phang2}{cmd:. coefconv, dominance notable}{p_end}
{phang2}{cmd:. display "Elasticity of mpg:           " r(elas_mpg)}{p_end}
{phang2}{cmd:. display "Pratt % of weight:           " r(pratt_pct_weight)}{p_end}
{phang2}{cmd:. display "Dominance % of weight:       " r(dom_pct_weight)}{p_end}

{pstd}Panel example — Family 8 fully populated{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtreg invest mvalue kstock, fe}{p_end}
{phang2}{cmd:. coefconv, plot dominance}{p_end}


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

{phang}
{bf:5.} For variables with many zeros, the growth-rate computation skips lags
that equal zero; a g_X built from a thin subset should be read with care.

{phang}
{bf:6.} Factor variables (e.g. {cmd:i.region}) are skipped in Families 2–8 and
in the dominance decomposition. Their raw β still appears in Family 1.

{phang}
{bf:7.} The {opt dominance} decomposition uses the OLS R² implied by the
correlation matrix as its denominator. For IV/FE models this is an
OLS-flavoured approximation, as is Pratt. Its cost is 2^k; see {opt maxdom()}.

{phang}
{bf:8.} For non-linear estimators ({cmd:logit}, {cmd:probit}, {cmd:tobit}),
{cmd:coefconv} reports OLS-style summaries with a warning; these are not
marginal effects. Use {helpb margins} instead.


{title:Technical notes}

{pstd}
{bf:Elasticity vs. semi-elasticities.} Elasticity requires proportional
changes in {it:both} X and Y (β·X̄/Ȳ). The X-semi-elasticity holds Y in levels
while expressing ΔX as a proportion (β·X̄, divide by 100 for a 1% ΔX). The
Y-semi-elasticity holds X in levels while expressing ΔY as a proportion
((β/Ȳ)·100). Only the full elasticity is unit-free.

{pstd}
{bf:Growth rate and the per-1%-of-X effect.} The {opt grate()} option
(Family 7) and the per-1%-of-X effect (Family 3, effect 10) compute the same
quantity when grate = 0.01; they differ only in framing.

{pstd}
{bf:Pratt vs. dominance.} Pratt is fast and additive but sign-sensitive and
can be distorted by collinearity. General dominance is non-negative,
correlation-robust, and sums to R², at the cost of a 2^k computation. Report
both when predictors are correlated.


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
