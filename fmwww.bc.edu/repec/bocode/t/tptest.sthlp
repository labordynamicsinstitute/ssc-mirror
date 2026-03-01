{smcl}
{* *! version 1.0.0  28feb2026}{...}
{vieweralsosee "utest" "help utest"}{...}
{vieweralsosee "nlcom" "help nlcom"}{...}
{vieweralsosee "margins" "help margins"}{...}
{vieweralsosee "regress" "help regress"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{viewerjumpto "Syntax" "tptest##syntax"}{...}
{viewerjumpto "Description" "tptest##description"}{...}
{viewerjumpto "Options" "tptest##options"}{...}
{viewerjumpto "Methodology" "tptest##methodology"}{...}
{viewerjumpto "Examples" "tptest##examples"}{...}
{viewerjumpto "Stored results" "tptest##results"}{...}
{viewerjumpto "References" "tptest##references"}{...}
{viewerjumpto "Author" "tptest##author"}{...}
{hline}
help for {cmd:tptest}{right:Version 1.0.0 — 28feb2026}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{bf:tptest} {hline 2}}Universal Turning Point & Inflection Point Test
with Sasabuchi, Simonsohn Two-Lines, Bootstrap, Delta-Method, and Fieller Inference{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:tptest} {it:x f(x)} [{it:f2(x)}]
[{cmd:,} {it:options}]

{pstd}
where {it:x} is the linear term, {it:f(x)} is the second-order term
(x², 1/x, or [ln(x)]²), and {it:f2(x)} is the optional third-order
term (x³) for cubic models.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Functional Form}
{synopt:{opt q:uadratic}}force quadratic: y = β₁·x + β₂·x²{p_end}
{synopt:{opt c:ubic}}force cubic: y = β₁·x + β₂·x² + β₃·x³{p_end}
{synopt:{opt i:nverse}}force inverse: y = β₁·x + β₂/x{p_end}
{synopt:{opt logq:uadratic}}force log-quadratic: ln(y) = β₁·ln(x) + β₂·[ln(x)]²{p_end}

{syntab:Test Methods}
{synopt:{opt d:elta}}delta-method SE and confidence interval for x*{p_end}
{synopt:{opt f:ieller}}Fieller (1954) confidence interval for x*{p_end}
{synopt:{opt two:lines}}Simonsohn (2018) two-lines test{p_end}
{synopt:{opt boot:strap}}parametric bootstrap confidence interval{p_end}
{synopt:{opt breps(#)}}number of bootstrap replications; default is {cmd:breps(1000)}{p_end}

{syntab:Test Bounds & Level}
{synopt:{opt mi:n(#)}}use {it:#} as lower bound of interval (default: data minimum){p_end}
{synopt:{opt ma:x(#)}}use {it:#} as upper bound of interval (default: data maximum){p_end}
{synopt:{opt inf:lection}}compute inflection point (cubic models only){p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Estimator Options}
{synopt:{opt pre:fix(string)}}equation prefix in {cmd:e(b)}, e.g., {it:ECT}{p_end}
{synopt:{opt eq(string)}}equation name, e.g., {it:LR}, {it:SR}, {it:ECT}{p_end}
{synopt:{opt tau(numlist)}}quantile(s) for multi-quantile turning point trajectory{p_end}

{syntab:Graph Options}
{synopt:{opt gr:aph}}produce publication-quality visualizations{p_end}
{synopt:{opt nogr:aph}}suppress graph output{p_end}
{synopt:{opt sav:ing(string)}}save graphs to files (base filename){p_end}
{synopt:{opt ti:tle(string)}}custom graph title{p_end}
{synopt:{opt graphopt(string)}}pass-through {cmd:twoway} graph options{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tptest} is a universal post-estimation command for testing turning points
(U-shaped or inverse U-shaped relationships) and inflection points. It provides
a comprehensive battery of modern inference methods for the extreme point x*
of fitted nonlinear relationships, integrating five distinct approaches:

{phang}
{bf:1. Sasabuchi (1980) / Lind & Mehlum (2010) test.}
The core hypothesis test for U-shape (or inverse U-shape) based on a composite
null. The test checks whether the slope is negative at the lower bound and
positive at the upper bound (U-shape), or vice versa (inverse U-shape).
The overall test statistic is the minimum of the absolute t-values at the
interval bounds.{p_end}

{phang}
{bf:2. Delta-method standard errors.}
Asymptotic standard errors and confidence intervals for the turning point x*
derived via the delta method: Var(x*) = G' · V · G, where G is the gradient
vector and V = e(V) is the variance-covariance matrix.{p_end}

{phang}
{bf:3. Fieller (1954) confidence interval.}
An exact confidence interval for the turning point based on the Fieller
method for ratios of normal random variables. Available for quadratic and
inverse specifications. Unlike the delta method, the Fieller CI has exact
coverage and does not rely on local linearity.{p_end}

{phang}
{bf:4. Simonsohn (2018) two-lines test.}
A non-parametric robustness check that splits the data at x* and estimates
separate linear regressions on each segment. For a valid U-shape, the left
slope must be significantly negative and the right slope significantly positive.
The joint p-value is the maximum of the individual one-sided p-values. This
test is robust to misspecification of the functional form. When the original
model is a panel estimator (e.g., {cmd:xtreg, fe}), the two-lines test
automatically matches the estimation method for each segment.{p_end}

{phang}
{bf:5. Parametric bootstrap CI.}
Confidence intervals obtained by drawing from the asymptotic distribution
N(β̂, V̂) of the estimated coefficients, computing x* for each draw, and
taking percentile-based intervals. Reports bootstrap SE, bias, and the
percentile CI. Useful when the delta-method normality approximation is
questionable.{p_end}

{pstd}
{cmd:tptest} supports four functional forms (auto-detected or user-specified):

{p2colset 5 28 30 2}{...}
{p2col :{bf:Quadratic}}y = β₁·x + β₂·x² → x* = −β₁/(2β₂){p_end}
{p2col :{bf:Cubic}}y = β₁·x + β₂·x² + β₃·x³ → turning point + inflection point{p_end}
{p2col :{bf:Inverse}}y = β₁·x + β₂/x → x* = √(β₂/β₁){p_end}
{p2col :{bf:Log-quadratic}}ln(y) = β₁·ln(x) + β₂·[ln(x)]² → x* = exp(−β₁/(2β₂)){p_end}
{p2colreset}{...}


{marker estimators}{...}
{title:Supported Estimators}

{pstd}
{cmd:tptest} works as a post-estimation command after any Stata estimator.
It auto-detects the preceding command and adapts equation prefixes accordingly.
It has been tested and optimized for:

{p2colset 5 32 34 2}{...}
{p2col :{it:Cross-section}}{cmd:regress}, {cmd:ardl}, {cmd:aardl}, {cmd:fbardl},
{cmd:fbnardl}, {cmd:mtnardl}, {cmd:tnardl}, {cmd:qardl}, {cmd:fqardl},
{cmd:qreg}, {cmd:ivregress}{p_end}
{p2col :{it:Panel}}{cmd:xtreg} (FE/RE), {cmd:xtpmg}, {cmd:pnardl},
{cmd:xtpqardl}, {cmd:areg}{p_end}
{p2col :{it:CS-Dependence}}{cmd:xtdcce2}, {cmd:xtcce}, {cmd:xtcspqardl}{p_end}
{p2col :{it:Quantile}}{cmd:qreg}, {cmd:sqreg}, {cmd:bsqreg}, {cmd:mmqreg},
{cmd:xtqreg}, {cmd:xtqsh}, {cmd:xtmdqr}, {cmd:rifhdreg}{p_end}
{p2colreset}{...}

{pstd}
For multi-equation models ({cmd:xtpmg}, {cmd:xtdcce2}, etc.), use
{opt eq()} or {opt prefix()} to specify the equation containing the
turning-point variables (e.g., {cmd:eq(ECT)} for the ECT equation in
{cmd:xtpmg}).


{marker options}{...}
{title:Options}

{dlgtab:Functional Form}

{phang}
{opt quadratic} forces interpretation as a quadratic specification:
y = β₁·x + β₂·x². If two variables are supplied and neither
{opt quadratic}, {opt inverse}, nor {opt logquadratic} is specified,
{cmd:tptest} auto-detects the form by comparing correlations with x² and 1/x.

{phang}
{opt cubic} forces interpretation as a cubic specification:
y = β₁·x + β₂·x² + β₃·x³. Three variables must be supplied.
If three variables are supplied without {opt cubic}, the cubic form is
auto-detected.

{phang}
{opt inverse} forces interpretation as an inverse specification:
y = β₁·x + β₂/x. The turning point is x* = √(β₂/β₁).

{phang}
{opt logquadratic} forces log-quadratic interpretation:
ln(y) = β₁·ln(x) + β₂·[ln(x)]². The turning point is
x* = exp(−β₁/(2β₂)), reported in the original scale of x.

{dlgtab:Test Methods}

{phang}
{opt delta} reports delta-method standard errors and confidence intervals
for the turning point x*. The SE is derived from the implicit function
theorem: SE(x*) = √(G'VG), where G = (∂x*/∂β₁, ∂x*/∂β₂, ...)'.

{phang}
{opt fieller} computes the Fieller (1954) confidence interval for x*.
Available for quadratic and inverse specifications. The Fieller CI
provides exact coverage when the ratio estimator may be poorly approximated
by normality. Reports "bounded", "unbounded", or "entire real line"
depending on the precision of β₂.

{phang}
{opt twolines} performs the Simonsohn (2018) two-lines test as a
robustness check. The data is split at the estimated turning point x*,
and separate linear regressions are estimated on each side:

{p 12 12 2}
Left:  E[y | x ≤ x*] = α_L + β_L · x{break}
Right: E[y | x > x*] = α_R + β_R · x{p_end}

{p 8 8 2}
For a valid U-shape: β_L < 0 (significantly) and β_R > 0 (significantly).{break}
Joint p-value = max(p_left, p_right) using one-sided tests.{break}
For panel estimators ({cmd:xtreg}), the test automatically matches the
original estimation method (FE/RE) for each segment.{p_end}

{phang}
{opt bootstrap} computes parametric bootstrap confidence intervals for x*.
Draws B replications from N(β̂, V̂), computes x* for each draw, and reports
the bootstrap SE, bias (mean − point estimate), and percentile CI.
Available for quadratic, inverse, and log-quadratic specifications.

{phang}
{opt breps(#)} specifies the number of bootstrap replications.
Default is {cmd:breps(1000)}. Recommended: 2000 for publication.

{dlgtab:Test Bounds & Level}

{phang}
{opt min(#)} sets the lower bound of the interval for the Sasabuchi test.
Default is the observed minimum of x in the data. Use this to test for
a turning point within a specific sub-range.

{phang}
{opt max(#)} sets the upper bound of the interval for the Sasabuchi test.
Default is the observed maximum of x in the data.

{phang}
{opt inflection} requests computation of the inflection point for cubic models.
The inflection point is x_ip = −β₂/(3β₃), with delta-method SE and CI.

{phang}
{opt level(#)} sets the confidence level for all CIs. Default is 95.

{dlgtab:Estimator Options}

{phang}
{opt prefix(string)} specifies the equation prefix used in {cmd:e(b)}
for multi-equation models. For example, after {cmd:xtpmg}, the ECT
equation coefficients may be stored with prefix "ECT:".

{phang}
{opt eq(string)} specifies the equation name. This is equivalent to
{opt prefix()} but appends the colon automatically. Example:
{cmd:eq(ECT)} is equivalent to {cmd:prefix(ECT:)}.

{phang}
{opt tau(numlist)} activates multi-quantile mode. For each quantile τ
in the list, {cmd:tptest} extracts the coefficients from the corresponding
equation in {cmd:e(b)} (as stored by {cmd:mmqreg}, {cmd:sqreg}, or other
multi-quantile estimators), computes x*(τ), and reports a trajectory table.
With {opt graph}, produces a turning-point trajectory plot showing how
x* varies across quantiles.

{dlgtab:Graph Options}

{phang}
{opt graph} produces publication-quality visualizations. The graphs
produced depend on the context:

{p 8 8 2}
{bf:Single-equation mode} (no {opt tau()}): three graphs are produced:{break}
  (1) Fitted curve with 95% CI and markers for data range and turning point{break}
  (2) Slope function dy/dx with zero-crossing at x*{break}
  (3) Combined panel of both graphs{p_end}

{p 8 8 2}
{bf:Multi-quantile mode} ({opt tau()} specified): a trajectory plot
showing x*(τ) vs. τ with confidence bands and significance markers.
Filled markers indicate significant U/inverse-U shape (p < 0.05);
hollow markers indicate non-significance.{p_end}

{phang}
{opt nograph} suppresses all graph output.

{phang}
{opt saving(string)} saves graph files using the specified base filename.
Three files are created: {it:basename}_curve.png, {it:basename}_slope.png,
and {it:basename}_combined.png. In multi-quantile mode, a single trajectory
plot is saved.

{phang}
{opt title(string)} overrides the default graph title.

{phang}
{opt graphopt(string)} passes additional options to the underlying
{cmd:twoway} graph command.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:Sasabuchi (1980) / Lind & Mehlum (2010) Test}

{pstd}
Consider a quadratic relationship y = β₁x + β₂x² estimated on the
interval [x_L, x_U]. The marginal effect is dy/dx = β₁ + 2β₂x.

{pstd}
{it:Test for U-shape:}

{p 8 12 2}
H₀: The relationship is monotone or inverse U-shaped{break}
H₁: The relationship is U-shaped (i.e., dy/dx < 0 at x_L and dy/dx > 0 at x_U){p_end}

{pstd}
{it:Test for inverse U-shape:}

{p 8 12 2}
H₀: The relationship is monotone or U-shaped{break}
H₁: The relationship is inverse U-shaped (dy/dx > 0 at x_L and dy/dx < 0 at x_U){p_end}

{pstd}
The test statistics at the bounds are:

{p 8 12 2}
t_L = (β₁ + 2β₂x_L) / √[Var(β₁) + 4x_L²Var(β₂) + 4x_L·Cov(β₁,β₂)]{break}
t_U = (β₁ + 2β₂x_U) / √[Var(β₁) + 4x_U²Var(β₂) + 4x_U·Cov(β₁,β₂)]{p_end}

{pstd}
The overall test statistic is t = min(|t_L|, |t_U|). Under H₀, the test
has exact size α when using one-sided critical values.

{pstd}
{bf:Turning Point Formulae}

{p2colset 5 28 30 2}{...}
{p2col :{it:Model}}{it:Turning point x*}{p_end}
{p2col :Quadratic}x* = −β₁/(2β₂){p_end}
{p2col :Cubic}dy/dx = β₁ + 2β₂x + 3β₃x² = 0 (quadratic formula){p_end}
{p2col :Inverse}x* = √(β₂/β₁){p_end}
{p2col :Log-quadratic}x* = exp[−β₁/(2β₂)]{p_end}
{p2colreset}{...}

{pstd}
{bf:Delta-Method Standard Errors}

{pstd}
For a turning point x* = g(β), the delta-method variance is:

{p 8 12 2}
Var(x*) = G' · V · G{p_end}

{p 8 12 2}
where G = ∂g/∂β is the gradient vector and V = e(V). For example, for
the quadratic case x* = −β₁/(2β₂):{break}
  G₁ = ∂x*/∂β₁ = −1/(2β₂){break}
  G₂ = ∂x*/∂β₂ = β₁/(2β₂²){p_end}

{pstd}
{bf:Fieller (1954) Confidence Interval}

{pstd}
The Fieller method constructs a CI for the turning point (a ratio of
correlated normal random variables) without relying on the delta-method
linearization. The interval is obtained by inverting the t-test for
the numerator coefficient evaluated at hypothesized values of the ratio.
The CI can be bounded (standard), unbounded (when β₂ is imprecisely
estimated), or the entire real line (when H₀: β₂ = 0 cannot be rejected).

{pstd}
{bf:Simonsohn (2018) Two-Lines Test}

{pstd}
A non-parametric robustness check for U-shaped relationships. Rather than
assuming a parametric functional form, the data is split at the estimated
turning point x*, and separate linear regressions are estimated:

{p 8 12 2}
Left segment (x ≤ x*):  y = α_L + β_L · x{break}
Right segment (x > x*): y = α_R + β_R · x{p_end}

{pstd}
For a valid U-shape, both β_L < 0 and β_R > 0 must be individually
significant. The joint p-value equals max(p_L, p_R), where p_L and p_R
are one-sided p-values. This test protects against false positives
from misspecified quadratic models (e.g., an exponential mistaken for
a U-shape).

{pstd}
{bf:Parametric Bootstrap}

{pstd}
The parametric bootstrap draws B replications β* ~ N(β̂, V̂) from the
asymptotic distribution, computes x*(β*) for each draw, and constructs:

{p 8 12 2}
Bootstrap SE = SD(x*₁, ..., x*_B){break}
Bootstrap bias = mean(x*_b) − x̂*{break}
Percentile CI = [x*_{(α/2)}, x*_{(1−α/2)}]{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic quadratic test (comparable to {cmd:utest})}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen mpg2 = mpg^2}{p_end}
{phang2}{cmd:. reg price mpg mpg2}{p_end}
{phang2}{cmd:. tptest mpg mpg2}{p_end}

{pstd}
{bf:Example 2: Full inference suite — all five methods}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen mpg2 = mpg^2}{p_end}
{phang2}{cmd:. reg price mpg mpg2}{p_end}
{phang2}{cmd:. tptest mpg mpg2, delta fieller twolines bootstrap breps(2000) graph saving("mytest")}{p_end}

{pstd}
{bf:Example 3: Custom interval bounds and confidence level}

{phang2}{cmd:. reg price mpg mpg2}{p_end}
{phang2}{cmd:. tptest mpg mpg2, min(15) max(35) level(90) delta fieller}{p_end}

{pstd}
{bf:Example 4: Inverse model}

{phang2}{cmd:. gen mpg_inv = 1/mpg}{p_end}
{phang2}{cmd:. reg price mpg mpg_inv}{p_end}
{phang2}{cmd:. tptest mpg mpg_inv, inverse delta fieller twolines bootstrap}{p_end}

{pstd}
{bf:Example 5: Log-quadratic (Environmental Kuznets Curve)}

{phang2}{cmd:. gen lnprice = ln(price)}{p_end}
{phang2}{cmd:. gen lnmpg = ln(mpg)}{p_end}
{phang2}{cmd:. gen lnmpg2 = lnmpg^2}{p_end}
{phang2}{cmd:. reg lnprice lnmpg lnmpg2}{p_end}
{phang2}{cmd:. tptest lnmpg lnmpg2, logquadratic delta twolines bootstrap breps(2000)}{p_end}

{pstd}
{bf:Example 6: Cubic model with inflection point}

{phang2}{cmd:. gen mpg3 = mpg^3}{p_end}
{phang2}{cmd:. reg price mpg mpg2 mpg3}{p_end}
{phang2}{cmd:. tptest mpg mpg2 mpg3, cubic inflection delta graph saving("cubic_test")}{p_end}

{pstd}
{bf:Example 7: Panel fixed effects (EKC-style)}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. gen ttl_exp2 = ttl_exp^2}{p_end}
{phang2}{cmd:. xtreg ln_wage ttl_exp ttl_exp2 tenure, fe}{p_end}
{phang2}{cmd:. tptest ttl_exp ttl_exp2, delta fieller twolines bootstrap breps(2000)}{p_end}

{pstd}
{bf:Example 8: Panel random effects}

{phang2}{cmd:. xtreg ln_wage ttl_exp ttl_exp2 tenure, re}{p_end}
{phang2}{cmd:. tptest ttl_exp ttl_exp2, delta twolines bootstrap}{p_end}

{pstd}
{bf:Example 9: Panel ARDL (xtpmg) — long-run turning point}

{phang2}{cmd:. xtpmg D.y L.y L.x L.x2, lr(L.y x x2) ec(ECT)}{p_end}
{phang2}{cmd:. tptest x x2, eq(ECT) delta graph}{p_end}

{pstd}
{bf:Example 10: Cross-sectional dependence (xtdcce2)}

{phang2}{cmd:. xtdcce2 y x x2, cr(x x2)}{p_end}
{phang2}{cmd:. tptest x x2, delta graph}{p_end}

{pstd}
{bf:Example 11: Quantile regression — multi-quantile trajectory}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen mpg2 = mpg^2}{p_end}
{phang2}{cmd:. mmqreg price mpg mpg2, q(10 25 50 75 90)}{p_end}
{phang2}{cmd:. tptest mpg mpg2, tau(.10 .25 .50 .75 .90) delta graph saving("qtrajectory")}{p_end}

{pstd}
{bf:Example 12: IV regression}

{phang2}{cmd:. gen weight2 = weight^2}{p_end}
{phang2}{cmd:. ivregress 2sls price (mpg mpg2 = weight weight2 length)}{p_end}
{phang2}{cmd:. tptest mpg mpg2, delta}{p_end}

{pstd}
{bf:Example 13: With control variables}

{phang2}{cmd:. reg price mpg mpg2 weight length foreign}{p_end}
{phang2}{cmd:. tptest mpg mpg2, delta fieller twolines}{p_end}

{pstd}
{bf:Example 14: Robust standard errors}

{phang2}{cmd:. reg price mpg mpg2, robust}{p_end}
{phang2}{cmd:. tptest mpg mpg2, delta fieller twolines bootstrap breps(2000)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tptest} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Core}}{p_end}
{synopt:{cmd:r(tp)}}turning point estimate x*{p_end}
{synopt:{cmd:r(extr)}}extreme point (= turning point){p_end}
{synopt:{cmd:r(t)}}overall t-value (Sasabuchi test){p_end}
{synopt:{cmd:r(p)}}overall p-value (one-sided){p_end}
{synopt:{cmd:r(x_l)}}lower bound of test interval{p_end}
{synopt:{cmd:r(x_u)}}upper bound of test interval{p_end}
{synopt:{cmd:r(s_l)}}slope at lower bound{p_end}
{synopt:{cmd:r(s_u)}}slope at upper bound{p_end}
{synopt:{cmd:r(t_l)}}t-value at lower bound{p_end}
{synopt:{cmd:r(t_u)}}t-value at upper bound{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Delta-method} (with {opt delta})}{p_end}
{synopt:{cmd:r(tp_se)}}delta-method standard error{p_end}
{synopt:{cmd:r(tp_ci_lo)}}lower CI bound (delta-method){p_end}
{synopt:{cmd:r(tp_ci_hi)}}upper CI bound (delta-method){p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Fieller} (with {opt fieller})}{p_end}
{synopt:{cmd:r(fieller_lo)}}Fieller CI lower bound{p_end}
{synopt:{cmd:r(fieller_hi)}}Fieller CI upper bound{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Two-lines test} (with {opt twolines})}{p_end}
{synopt:{cmd:r(tl_slope_l)}}left-segment slope (β_L){p_end}
{synopt:{cmd:r(tl_slope_r)}}right-segment slope (β_R){p_end}
{synopt:{cmd:r(tl_t_l)}}left-segment t-value{p_end}
{synopt:{cmd:r(tl_t_r)}}right-segment t-value{p_end}
{synopt:{cmd:r(tl_p_l)}}left-segment p-value (two-sided){p_end}
{synopt:{cmd:r(tl_p_r)}}right-segment p-value (two-sided){p_end}
{synopt:{cmd:r(tl_p_joint)}}joint p-value (Simonsohn test){p_end}
{synopt:{cmd:r(tl_n_l)}}N in left segment{p_end}
{synopt:{cmd:r(tl_n_r)}}N in right segment{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Bootstrap} (with {opt bootstrap})}{p_end}
{synopt:{cmd:r(bs_se)}}bootstrap standard error{p_end}
{synopt:{cmd:r(bs_bias)}}bootstrap bias{p_end}
{synopt:{cmd:r(bs_ci_lo)}}bootstrap CI lower bound (percentile){p_end}
{synopt:{cmd:r(bs_ci_hi)}}bootstrap CI upper bound (percentile){p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Scalars — Cubic} (with {opt cubic})}{p_end}
{synopt:{cmd:r(ip)}}inflection point{p_end}
{synopt:{cmd:r(ip_se)}}inflection point SE (delta-method){p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Macros}}{p_end}
{synopt:{cmd:r(shape)}}detected shape: "U shape" or "Inverse U shape"{p_end}
{synopt:{cmd:r(model)}}functional form: "quad", "cubic", "inv", "logquad"{p_end}
{synopt:{cmd:r(spec)}}specification label: "Quadratic", "Cubic", etc.{p_end}
{synopt:{cmd:r(cmd_used)}}name of the preceding estimation command{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: {bf:Matrices — Multi-quantile} (with {opt tau()})}{p_end}
{synopt:{cmd:r(tp_trajectory)}}matrix of (τ, x*, SE, t, p) per quantile{p_end}
{synopt:{cmd:r(n_tau)}}number of quantiles{p_end}
{p2colreset}{...}


{title:Comparison with utest}

{pstd}
{cmd:tptest} is fully backward-compatible with {cmd:utest} for quadratic
and inverse specifications. The table below summarizes the differences:

{p2colset 5 34 36 2}{...}
{p2col :{it:Feature}}{it:utest}{space 6}{it:tptest}{p_end}
{p2col :Quadratic}✓{space 8}✓{p_end}
{p2col :Inverse}✓{space 8}✓{p_end}
{p2col :Cubic / Inflection point}{space 9}✓{p_end}
{p2col :Log-quadratic}{space 9}✓{p_end}
{p2col :Auto-detect functional form}{space 9}✓{p_end}
{p2col :Delta-method SE & CI}{space 9}✓{p_end}
{p2col :Fieller CI}✓{space 8}✓{p_end}
{p2col :Simonsohn (2018) two-lines}{space 9}✓{p_end}
{p2col :Parametric bootstrap CI}{space 9}✓{p_end}
{p2col :Multi-quantile tau()}{space 9}✓{p_end}
{p2col :Publication-quality graphs}{space 9}✓{p_end}
{p2col :Auto-detect 20+ estimators}{space 9}✓{p_end}
{p2col :Panel FE/RE support}{space 9}✓{p_end}
{p2col :xtpmg/xtdcce2/xtcspqardl}{space 9}✓{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Lind, J.T. and H. Mehlum (2010).
{it:With or without U? The appropriate test for a U-shaped relationship.}
Oxford Bulletin of Economics and Statistics, 72(1): 109-118.
{browse "https://doi.org/10.1111/j.1468-0084.2009.00569.x"}
{p_end}

{phang}
Sasabuchi, S. (1980).
{it:A test of a multivariate normal mean with composite hypotheses determined by linear inequalities.}
Biometrika, 67(2): 429-439.
{browse "https://doi.org/10.1093/biomet/67.2.429"}
{p_end}

{phang}
Simonsohn, U. (2018).
{it:Two lines: A valid alternative to the invalid testing of U-shaped relationships with quadratic regressions.}
Advances in Methods and Practices in Psychological Science, 1(4): 538-555.
{browse "https://doi.org/10.1177/2515245918805755"}
{p_end}

{phang}
Fieller, E.C. (1954).
{it:Some problems in interval estimation.}
Journal of the Royal Statistical Society, Series B, 16(2): 175-185.
{browse "https://doi.org/10.1111/j.2517-6161.1954.tb00159.x"}
{p_end}

{phang}
Efron, B. and R.J. Tibshirani (1993).
{it:An Introduction to the Bootstrap.}
Chapman & Hall/CRC.
{p_end}


{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 14 or later.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}

{pstd}
Please cite this package as:{break}
Roudane, M. (2026). TPTEST: Stata module for universal turning point and
inflection point testing. Statistical Software Components, Boston College
Department of Economics.
{p_end}


{title:Also see}

{pstd}
{help utest}, {help nlcom}, {help margins}, {help test}, {help regress},
{help xtreg}, {help qreg}, {help mmqreg}
{p_end}
