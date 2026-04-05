{smcl}
{* coefconv.sthlp — help file for coefconv v1.0.0 *}
{hline}
{title:Title}

{pstd}{bf:coefconv} — Comprehensive marginal effects from regression slope coefficients{p_end}

{hline}
{title:Syntax}

{pstd}
{cmd:coefconv} [{cmd:,} {it:options}]
{p_end}

{synoptset 26 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt gr:ate(#)}}growth rate for default ΔX = grate × X̄; default {bf:0.01} (1%){p_end}
{synopt:{opt quan:tiles(numlist)}}add extra percentiles beyond default {10 25 50 75 90}{p_end}
{synopt:{opt delta(numlist)}}custom ΔX values applied to every predictor{p_end}
{synopt:{opt sav:ing(filename[,replace])}}save wide results dataset (one row per predictor){p_end}
{synopt:{opt notable}}suppress all display output{p_end}
{synopt:{opt for:mat(fmt)}}Stata number format; default {bf:%12.6f}{p_end}
{synoptline}

{hline}
{title:Description}

{pstd}
{cmd:coefconv} computes 23+ marginal effect types for every predictor in the
most recently estimated regression model.  It draws all inputs from Stata's
{cmd:e()} results (slopes, variable names, estimation sample) plus live
descriptive statistics ({cmd:summarize}, {cmd:_pctile}, {cmd:correlate})
so no separate data-preparation step is needed.

{pstd}
{cmd:coefconv} is designed to run immediately after {cmd:regress},
{cmd:ivregress}, {cmd:areg}, or {cmd:xtreg}.  It will also run after
non-linear estimators but will warn that linear-slope marginal effects
are approximations in those cases.

{hline}
{title:Interpretation Guide}

{pstd}
All examples below use a single illustrative wage regression to keep numbers
consistent across all effect types:

{pmore}
{cmd:. regress hourly_wage education experience}

{pmore}
Model statistics: N = 500,  R² = 0.42,  RMSE = 4.58
{p_end}
{pmore}
Ȳ = 18.00  (mean hourly wage, $),  σY = 6.00
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

{dlgtab:Family 1 — Raw & Standardized Slopes}

{pstd}
These four measures all express the slope on different scales.
They answer: "how big is this effect, and how does it compare
across predictors measured in different units?"

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
{p2col:}{it:Template}: A 1-unit increase in X is associated with wages changing by
(β/Ȳ×100) percent of the mean of Y.{p_end}
{p2col:}{it:Example}: (1.20/18.00)×100 = 6.667  →  "Each additional year of education
is associated with wages increasing by 6.67% of the average wage.
At a mean wage of $18.00, this corresponds to $1.20/hour."{p_end}
{p2col:}{it:When to use}: A percentage version of the proportional ME above — easier
to communicate to non-technical audiences. Answers "what fraction of
a typical outcome does this effect represent?"{p_end}

{dlgtab:Family 5 — Variance & Importance Measures}

{pstd}
These decompose the model's R² to quantify each predictor's contribution
to explained variance. They answer: "which predictor matters most?"

{p2col:{bf:13. Squared Std. Coef. (β*²)}}Formula: (β × σX/σY)²{p_end}
{p2col:}{it:Template}: β*² approximates the proportion of Y's variance uniquely
attributable to X (exact only if all predictors are uncorrelated).{p_end}
{p2col:}{it:Example}: β*² = 0.60² = 0.36  →  "Under orthogonality, education would
account for approximately 36% of the variance in wages. In practice,
with correlated predictors, this overstates unique contribution."{p_end}
{p2col:}{it:When to use}: A quick, intuitive importance metric. Interpret cautiously
with correlated predictors — use Pratt's measure instead.{p_end}

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
{p2col:}{it:Template}: Education's standardized contribution to R². The Pratt %
of R² (shown in the summary table) = this value divided by Σ(β*×r).{p_end}
{p2col:}{it:Example}: 0.60 × 0.55 = 0.330  →  If Σ(β*×r) = 0.42 (= R²),
then education's Pratt % = 0.330/0.420 = 78.6% of explained variance.
"Education accounts for 78.6% of the variance explained by the model."{p_end}
{p2col:}{it:Note}: Pratt indices sum to exactly 100% of R² across all predictors.
A negative Pratt index identifies a {it:suppressor variable}: a predictor
that increases the explanatory power of other variables despite having
a sign-discordant zero-order relationship with Y.{p_end}

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
{p2col:}{it:Example (p50 → p10)}: ΔX = 10 − 14 = −4.00,  ΔY = 1.20 × (−4) = −4.80
→  "Workers at the 10th percentile earn $4.80/hour less than median workers."{p_end}
{p2col:}{it:When to use}: Policy scenarios where you want to express effects in terms
of realistic population movements (e.g., "what would it mean to bring
low-education workers up to the median?"). More grounded than abstract
1-unit or 1-SD changes.{p_end}

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
(e.g., a 5% increase in R&D spending, a 2% reduction in interest rates).
The growth-rate framing is natural when X is a stock or level variable.{p_end}

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
within the observed data. Useful for gauging the ceiling of a
predictor's reach. Sensitive to extreme outliers in X.{p_end}

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
following Gelman & Hill's recommendation to use 2-SD scaling for
binary/continuous comparisons.{p_end}

{p2col:{bf:26. Custom ΔX Effects (delta() option)}}Formula: β × ΔX_user{p_end}
{p2col:}{it:Template}: Each value supplied in {opt delta()} is treated as a specific
ΔX; the corresponding ΔY = β × ΔX is displayed for every predictor.{p_end}
{p2col:}{it:Example}: {cmd:coefconv, delta(2 5)}  →  For education:
ΔX = 2: ΔY = 1.20×2 = 2.40  →  "Two extra years of school: +$2.40/hour"
ΔX = 5: ΔY = 1.20×5 = 6.00  →  "Five extra years of school: +$6.00/hour"{p_end}
{p2col:}{it:When to use}: Policy simulations with a specific, externally defined
change (e.g., a 500 calorie dietary intervention, a $1000 subsidy,
a 3-point rate cut). Cuts through all standardization and gives a
direct answer to "what happens if we change X by exactly this much?"{p_end}

{hline}
{title:Returned Results}

{pstd}{cmd:r()} scalars:{p_end}
{p2colset 6 32 34 2}
{p2col:{cmd:r(N)}}number of observations{p_end}
{p2col:{cmd:r(r2)}}R-squared{p_end}
{p2col:{cmd:r(ymean)}}mean of dependent variable{p_end}
{p2col:{cmd:r(ysd)}}SD of dependent variable{p_end}
{p2col:{cmd:r(pratt_tot)}}sum of Pratt numerators (equals R²){p_end}
{p2col:{cmd:r(b_{it:varname})}}raw slope for each predictor{p_end}
{p2col:{cmd:r(bstd_{it:varname})}}standardized slope for each predictor{p_end}
{p2col:{cmd:r(elas_{it:varname})}}elasticity at means for each predictor{p_end}
{p2col:{cmd:r(ysemi_{it:varname})}}Y-semi-elasticity for each predictor{p_end}
{p2col:{cmd:r(pratt_n_{it:varname})}}Pratt numerator for each predictor{p_end}
{p2col:{cmd:r(pratt_pct_{it:varname})}}Pratt % of R² for each predictor{p_end}

{hline}
{title:Usage Examples}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv}{p_end}

{phang2}{it:// Custom growth rate (5%) and extra tail quantiles}{p_end}
{phang2}{cmd:. coefconv, grate(0.05) quantiles(5 95)}{p_end}

{phang2}{it:// Custom ΔX values: specific policy scenarios}{p_end}
{phang2}{cmd:. coefconv, delta(500 1000 5000)}{p_end}

{phang2}{it:// Save wide results dataset for further analysis}{p_end}
{phang2}{cmd:. coefconv, saving(coefconv_results, replace)}{p_end}

{phang2}{it:// Silent run — retrieve scalars programmatically}{p_end}
{phang2}{cmd:. coefconv, notable}{p_end}
{phang2}{cmd:. display "Elasticity of mpg: " r(elas_mpg)}{p_end}
{phang2}{cmd:. display "Pratt share of weight: " r(pratt_pct_weight) "%"}{p_end}

{phang2}{it:// Full custom run: 2% growth, extra quantiles, two delta scenarios}{p_end}
{phang2}{cmd:. coefconv, grate(0.02) quantiles(1 5 95 99) delta(100 500) format(%10.4f)}{p_end}

{hline}
{title:Technical Notes}

{pstd}
{bf:Elasticity vs. semi-elasticities}: Elasticity requires proportional changes
in {it:both} X and Y (β·X̄/Ȳ). The X-semi-elasticity holds Y in levels while
expressing ΔX as a proportion (β·X̄, divide by 100 for a 1% ΔX). The
Y-semi-elasticity holds X in levels while expressing ΔY as a proportion
((β/Ȳ)·100). Only the full elasticity is unit-free.

{pstd}
{bf:Pratt's measure and suppressors}: Pratt indices are signed and sum to
exactly 100% of R². A {it:negative} Pratt index identifies a suppressor
variable: a predictor whose bivariate correlation with Y is weaker (or
opposite in sign) than its partial relationship, because it absorbs
error variance from other predictors. Do not exclude suppressor variables
from the model based on this alone.

{pstd}
{bf:Linear models and Family 6}: Because OLS produces a constant slope, the
marginal effect is β everywhere — the "effect at the mean" and "effect at
the median" are numerically identical. Family 6 instead shows the discrete
ΔY from moving X from its median to each quantile, which is a more
informative use of the distributional structure.

{pstd}
{bf:Growth rate and the per-1%-of-X effect}: The {opt grate()} option
(Family 7) and the per-1%-of-X effect (Family 3, effect 10) compute the
same quantity when grate = 0.01. They differ only in framing: {opt grate()}
is presented as a "growth scenario" (proportional expansion of X), while
effect 10 is framed as "a 1% increase from the mean."

{hline}
{title:Author}

{pstd}
Dr Noman Arshed{break}
Senior Lecturer, Department of Business Analytics{break}
Sunway Business School, Sunway University{break}
{browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}
{p_end}

{title:Also see}
{pstd}{helpb regress}, {helpb ivregress}, {helpb areg}, {helpb xtreg},
{helpb margins}, {helpb estat summarize}{p_end}
