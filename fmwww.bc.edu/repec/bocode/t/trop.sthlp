{smcl}
{vieweralsosee "trop estat" "help trop_estat"}{...}
{vieweralsosee "trop predict" "help trop_predict"}{...}
{viewerjumpto "Syntax" "trop##syntax"}{...}
{viewerjumpto "Description" "trop##description"}{...}
{viewerjumpto "Options" "trop##options"}{...}
{viewerjumpto "Remarks" "trop##remarks"}{...}
{viewerjumpto "Examples" "trop##examples"}{...}
{viewerjumpto "Stored results" "trop##results"}{...}
{viewerjumpto "Methods and formulas" "trop##methods"}{...}
{viewerjumpto "Implementation notes" "trop##implementation_notes"}{...}
{viewerjumpto "References" "trop##references"}{...}
{viewerjumpto "Author" "trop##author"}{...}
{viewerjumpto "Installation" "trop##installation"}{...}
{viewerjumpto "Also see" "trop##alsosee"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:trop} {hline 2}}Triply Robust Panel Estimator{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:trop} {depvar} {it:treatvar} {ifin} {weight}{cmd:,} {opth panelvar(varname)} {opth timevar(varname)}
[{it:options}]

{pstd}
{cmd:pweight}s are allowed and must be constant within a panel unit; see
{help trop##survey_weights:Survey weights}.

{pstd}
{cmd:trop, version} displays the installed package version and exits without
requiring {it:depvar} / {it:treatvar}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth panelvar(varname)}}panel unit identifier{p_end}
{synopt:{opth timevar(varname)}}time period identifier{p_end}

{syntab:Estimation Method}
{synopt:{opt method(twostep|joint|local|global)}}estimation method; default is {cmd:twostep}, the paper's main Algorithm 2 estimator.  {cmd:local} is an alias for {cmd:twostep} and {cmd:global} for {cmd:joint}, matching the paper terminology.{p_end}

{syntab:Lambda Grid Settings}
{synopt:{opt grid_style(default|fine|extended)}}preset lambda grid; default is {cmd:default}{p_end}
{synopt:{opth lambda_time_grid(numlist)}}custom lambda_time grid values{p_end}
{synopt:{opth lambda_unit_grid(numlist)}}custom lambda_unit grid values{p_end}
{synopt:{opth lambda_nn_grid(numlist)}}custom lambda_nn grid values{p_end}

{syntab:LOOCV Control}
{synopt:{opth fixedlambda(numlist)}}skip LOOCV; use fixed lambda values (3 values){p_end}
{synopt:{opt twostep_loocv(cycling|exhaustive)}}twostep-method LOOCV search strategy; default is {cmd:cycling}{p_end}
{synopt:{opt joint_loocv(cycling|exhaustive)}}joint-method LOOCV search strategy; default is {cmd:exhaustive}{p_end}
{synopt:{opt tol(#)}}convergence tolerance; default is {cmd:1e-6}{p_end}
{synopt:{opt maxiter(#)}}maximum iterations; default is {cmd:500}{p_end}

{syntab:Bootstrap Inference}
{synopt:{opt bootstrap(#)}}bootstrap replications (paper Alg 3); default is {cmd:200}; set {cmd:0} to skip{p_end}
{synopt:{opt bsalpha(#)}}deprecated significance level alias; overrides {opt level()} when supplied{p_end}
{synopt:{opt bsvariance(sample|paper)}}bootstrap variance denominator; default is {cmd:sample} (1/(B-1)); use {cmd:paper} for the Alg 3 denominator (1/B){p_end}
{synopt:{opt cimethod(percentile|t|normal)}}primary confidence interval type; default is {cmd:percentile} (Alg 3 step 6) when bootstrap is enabled, otherwise {cmd:t}{p_end}

{syntab:Covariates}
{synopt:{opth covariates(varlist)}}covariates for Eq. 14 adjustment (paper Section 6.2){p_end}

{syntab:Survey Design}
{synopt:{opth strata(varname)}}stratification variable for Rao-Wu bootstrap{p_end}
{synopt:{opth psu(varname)}}primary sampling unit variable{p_end}
{synopt:{opth fpc(varname)}}finite population correction variable{p_end}
{synopt:{opt nest}}nest PSU within strata{p_end}
{synopt:{opt singleunit(centered|skip)}}lonely PSU handling strategy; default is {cmd:skip}{p_end}

{syntab:Other}
{synopt:{opt seed(#)}}random number seed; default is {cmd:42}{p_end}
{synopt:{opt level(#)}}confidence level; default is {cmd:c(level)}{p_end}
{synopt:{opt vlevel(#)}}verbose output level (0-4); default is {cmd:0}{p_end}
{synopt:{opt verbose}}display detailed progress information (equivalent to {cmd:vlevel(2)}){p_end}
{synopt:{opt notiming}}suppress timing estimate display{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:trop} implements the Triply Robust Panel (TROP) estimator proposed by
Athey, Imbens, Qu, and Viviano (2025) for estimating the average treatment
effect on the treated (ATT) in panel data settings.  The estimator combines
unit weights, time weights, and a nuclear-norm regularized low-rank factor
model to predict counterfactual outcomes for treated unit-time pairs.

{pstd}
The triple robustness property (Theorem 5.1) ensures that the bias of the
estimator is bounded by the product of three components: unit imbalance,
time imbalance, and misspecification of the regression adjustment.  The
estimator is consistent if any one of the three components is zero
(Corollary 1).

{pstd}
Two estimation methods are available:

{phang}
{opt twostep} (default) implements Algorithm 2 of the paper, which estimates
individual treatment effects for each treated unit-time pair (Eq. 13 /
Eq. 2 at the cell level), allowing for heterogeneous effects across units
and time periods, and then aggregates to ATT via Eq. 1.  This is the
primary estimator exposed by {cmd:trop} and the recommended choice unless
a homogeneous-effect restriction is substantively justified.

{phang}
{opt joint} implements the aggregation strategy described in Remark 6.1,
which assumes homogeneous treatment effects and estimates a single scalar
tau via weighted least squares.  Because Remark 6.1 does not specify
concrete time/unit kernels, this method uses a natural adaptation of
Eq. 3: time weights decay from the centre of the treated block, and unit
weights decay in the RMSE of each unit's pre-treatment trajectory against
the average treated trajectory (see Remarks below).  This shared-weight
extension is most appropriate under simultaneous adoption, where the same
treated block is meaningful across all treated units.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth panelvar(varname)} specifies the variable that identifies the panel
units (e.g., individuals, firms, countries).

{phang}
{opth timevar(varname)} specifies the variable that identifies the time
periods.

{dlgtab:Estimation Method}

{phang}
{opt method(twostep|joint|local|global)} specifies the estimation method.
Paper-consistent aliases are accepted: {cmd:local} is identical to {cmd:twostep}
(per-observation weights, Algorithm 2) and {cmd:global} is identical to
{cmd:joint} (shared-weight estimator, Remark 6.1).  Any other value is
rejected with r(198).

{pmore}
{opt twostep} (default) uses per-observation weights following Algorithm 2.
This allows for heterogeneous treatment effects and is the recommended
approach.  Use this when treatment effects may vary across units, across
post-treatment periods, or both.  {opt twostep} supports arbitrary 0/1
treatment matrices, including staggered adoption and switching treatments
(units turning treatment on and off).

{pmore}
{opt joint} uses global weights following Remark 6.1. This assumes
homogeneous treatment effects but provides higher precision when the
assumption holds.  Because the same weight system is shared across treated
cells, {opt joint} requires a simultaneous-adoption, absorbing design and
rejects staggered adoption and switching treatments with r(459); use
{opt twostep} for those patterns.

{dlgtab:Lambda Grid Settings}

{phang}
{opt grid_style(default|fine|extended)} specifies a preset lambda grid for
LOOCV hyperparameter selection.

{pmore}
{opt default} uses 180 combinations (6x6x5) and is recommended for
most applications.  The {bf:lambda_nn} dimension is a five-point
log-decade ladder {c -(}0, 0.01, 0.1, 1, 10{c )-}, which excludes the
DID/TWFE corner (lambda_nn = +infinity) for predictable LOOCV cost.

{pmore}
{opt fine} uses 343 combinations (7x7x7) and inserts half-decade steps
({cmd:0.0316}, {cmd:0.316}) into the critical 0.01-1 band of the
{bf:lambda_nn} grid and a {cmd:0.3} point into the {bf:lambda_time} and
{bf:lambda_unit} grids.  Recommended for small panels (e.g. the paper's
Basque and West Germany applications) where the LOOCV objective
{bf:Q(lambda)} surface is non-convex and coarser grids can produce
platform-dependent lambda selections.

{pmore}
{opt extended} uses 4,256 combinations (14x16x19) covering all optimal
values from Table 2 of the paper. This provides a finer search but is
computationally more expensive.

{phang}
{opth lambda_time_grid(numlist)} specifies custom values for lambda_time.
Overrides {opt grid_style()} for this parameter.  Values must be finite and
non-negative: Stata missing ({cmd:.}) is rejected at parse time because the
corresponding degenerate kernel (all weight collapsed onto the target
period) has no counterpart in paper Eq. (3).

{phang}
{opth lambda_unit_grid(numlist)} specifies custom values for lambda_unit.
Same finiteness requirement as {opt lambda_time_grid()}: Stata missing is
rejected at parse time.

{phang}
{opth lambda_nn_grid(numlist)} specifies custom values for lambda_nn (nuclear
norm penalty). Overrides {opt grid_style()} for this parameter.  Stata
missing ({cmd:.}) is accepted and interpreted as +infinity (paper Eq. 2
remark), which zeros the low-rank component L and yields the classical
DID / TWFE special case.  The {opt grid_style(default)} preset does not
include this corner; opt in via {opt grid_style(extended)} or a custom
{opt lambda_nn_grid()} that contains {cmd:.} or a sufficiently large value.

{pmore}
{bf:Performance caveat (large panels):} lambda_nn values in the open interval
{cmd:(0, 0.1)} - most notably the {cmd:0.01} point of the default grid - are by
far the most expensive to evaluate. For {cmd:0 < lambda_nn < 0.1} the
nuclear-norm subproblem is solved by FISTA with the inner-iteration cap raised
to 50, and every inner step costs one full T-by-N SVD; by contrast
{cmd:lambda_nn = 0} and {cmd:lambda_nn >= 0.1} take cheap closed-form paths.
On a large panel a single interior candidate can therefore dominate the whole
search: at roughly 8,300 control cells one such point was measured tens of
thousands of times slower per cell than {cmd:lambda_nn = 0} (about 12,600
ms/cell versus about 0.2 ms/cell), i.e. tens of hours for that one candidate
alone. Large-panel users are advised to supply a custom grid that avoids the
open interval, e.g. {cmd:lambda_nn_grid(0 1 10)}, which keeps only the cheap
regimes.

{phang}
{opt joint_loocv(cycling|exhaustive)} selects the LOOCV search strategy for
the joint method. Only effective when {opt method(joint)} is combined with
LOOCV (that is, {opt fixedlambda()} is not specified).

{pmore}
{opt exhaustive} (default) evaluates every (lambda_time, lambda_unit,
lambda_nn) combination in the Cartesian product of the three grids in
parallel and returns the exact argmin of {bf:Q(lambda)} over the grid.
Cost is O(|grid|^3) and may be expensive on dense grids.

{pmore}
{opt cycling} runs a two-stage coordinate-descent search adapted from
Footnote 2 of Athey et al. (2025): univariate sweeps with extreme fixed
values produce initial estimates, then each parameter is updated cyclically
while the others are held at their current optimum. Cost is
O(|grid| * max_cycles).  Prefer {opt cycling} on dense grids ({opt grid_style(extended)}
or larger custom grids) where the O(|grid|^3) exhaustive cost becomes
prohibitive; it matches {bf:exhaustive} to within the LOOCV tie tolerance
on all benchmark panels but may miss non-convex local minima on small panels.

{phang}
{opt twostep_loocv(cycling|exhaustive)} selects the LOOCV search strategy
for the twostep method. Only effective when {opt method(twostep)} is
combined with LOOCV.

{pmore}
{opt cycling} (default) runs coordinate descent over the per-observation
LOOCV objective, matching the historical Stata behaviour.  Cost is
O(|grid| * max_cycles) per evaluated control cell, so it scales well even
with {opt grid_style(extended)} and is the recommended default on
medium-to-large panels (N * T &gt;= 400).

{pmore}
{opt exhaustive} enumerates the full Cartesian product of the three
lambda grids and returns the global grid minimum.  A deterministic
lex-order tie-breaker
(largest {bf:lambda_nn} &gt; smallest {bf:lambda_time} &gt; smallest
{bf:lambda_unit}) resolves near-ties within 1e-12 of the best score so
that cross-BLAS or cross-platform runs return identical lambdas.
Recommended for small panels (e.g. the paper's Basque and West Germany
applications, N * T &lt; 200) where the Q(lambda) surface is non-convex and
coordinate descent may stall at platform-dependent local minima.  Example:
{cmd:trop y d, panelvar(id) timevar(t) grid_style(fine) twostep_loocv(exhaustive)}.

{pmore}
{bf:Infinity values:} Use {cmd:.} (missing) or {cmd:1e10} to represent
infinity in custom grids. For lambda_time and lambda_unit, infinity means
uniform weights. For lambda_nn, infinity disables the low-rank factor model.

{dlgtab:LOOCV Control}

{pstd}
{bf:Computational cost:} LOOCV evaluates the cross-validation criterion for each
control observation across all grid points.  For panels with N*T > 500 control
cells, consider using {cmd:fixedlambda()} with theoretically motivated values,
or reducing the grid with {cmd:grid_style(default)}.
{p_end}

{phang}
{opth fixedlambda(numlist)} specifies fixed values for (lambda_time,
lambda_unit, lambda_nn), bypassing LOOCV hyperparameter selection entirely.
Exactly 3 non-negative values must be provided.

{pmore}
Example: {cmd:fixedlambda(0.5 1.0 0.1)} sets lambda_time=0.5,
lambda_unit=1.0, lambda_nn=0.1. When this option is specified,
{opt grid_style()} is ignored.
{opt tol()} and {opt maxiter()} still apply to the alternating minimization
in the estimation step.

{phang}
{opt tol(#)} specifies the convergence tolerance for the alternating
minimization algorithm. Default is {cmd:1e-6}.

{phang}
{opt maxiter(#)} specifies the maximum number of iterations for the
alternating minimization algorithm. Default is {cmd:500}.

{pstd}
For large panels (N > 30 or T > 25), the default {cmd:maxiter(500)} may be
insufficient for convergence.  Consider increasing to {cmd:maxiter(1000)} or
{cmd:maxiter(2000)} for such cases.  Convergence status is reported in
{cmd:e(converged)}.
{p_end}

{dlgtab:Bootstrap Inference}

{phang}
{opt bootstrap(#)} specifies the number of bootstrap replications for
variance estimation following Algorithm 3 of the paper. Default is {cmd:200}.
Set to {cmd:0} to skip bootstrap inference; the point estimate is still
returned but standard errors, p-values, and confidence intervals are not
computed. The bootstrap constructs each replicate by sampling N_0 control
units with replacement and N_1 treated units with replacement separately.

{pstd}
{bf:Performance note:} Each bootstrap replication requires a full model re-estimation.
For panels with N > 20 units, expect ~5-10 seconds per replication.
Use {cmd:bootstrap(30)} for quick diagnostics or {cmd:bootstrap(200)} for
publication-quality inference.
{p_end}

{pmore}
{bf:Confidence intervals.} Three candidate intervals are always computed
and stored whenever bootstrap is enabled; the option {opt cimethod()}
selects which one is promoted to the primary pair
{cmd:e(ci_lower)}/{cmd:e(ci_upper)}.

{phang2}
(a) {it:t-based} CI {cmd:e(ci_lower_t)}/{cmd:e(ci_upper_t)} computed as
{cmd:att} {bf:{c 177}} {it:t}_{it:df_r}(1-alpha/2) * {cmd:se}, with the
bootstrap standard error and a t(N_1 - 1) reference distribution, where
N_1 is the number of ever-treated units.  The unit-level stratified
resampling in Algorithm 3 makes N_1 the cluster count that governs the
small-sample df.  When N_1 < 2 the t-wrap collapses to the normal wrap.

{phang2}
(b) {it:normal-wrap} CI {cmd:e(ci_lower_normal)}/{cmd:e(ci_upper_normal)}
using the standard-normal 1-alpha/2 quantile.  Defined whenever the SE
is defined; identical to the t-wrap in the large-sample limit.

{phang2}
(c) {it:percentile} CI
{cmd:e(ci_lower_percentile)}/{cmd:e(ci_upper_percentile)}
taken directly from the alpha/2 and 1-alpha/2 quantiles of the bootstrap
empirical distribution (step 6 of Algorithm 3).  Distribution-free under
the bootstrap exchangeability assumption, and invariant under monotone
reparameterisations of tau.

{pmore}
All three intervals share the same confidence level {cmd:level()}.  The
primary interval is echoed first in the results table with a
{cmd:[<method>]} tag; the two non-primary intervals are echoed directly
below for comparison.  Large discrepancies between the parametric and
percentile intervals suggest asymmetry or heavy tails in the bootstrap
distribution and warrant investigation.

{phang}
{opt cimethod(percentile | t | normal)} selects which interval populates
the primary {cmd:e(ci_lower)}/{cmd:e(ci_upper)} pair.  The default is
{opt percentile} whenever {cmd:bootstrap > 0} (Algorithm 3 step 6) and
{opt t} otherwise.  When {cmd:bootstrap = 0} an explicit
{opt cimethod(percentile)} downgrades to {opt t} and emits a note; in that
case the downgrade trace is recorded in {cmd:e(cimethod)} as
{cmd:"percentile->t"}.  The three candidate pairs listed above are always
written to {cmd:e()} independently of {opt cimethod()} so downstream code
can switch primary without re-estimating.

{phang}
{opt bsvariance(sample|paper)} selects the denominator used to build the
bootstrap standard error {cmd:e(se)}.

{pmore}
{opt sample} (default) divides the sum of squared centred replicate
estimates by {it:B} - 1, yielding the Bessel-corrected sample variance.
This is the unbiased estimator for the bootstrap variance and is the
conventional choice in bootstrap practice and in Stata's other bootstrap
commands.

{pmore}
{opt paper} divides by {it:B}, matching the denominator that appears
explicitly in Algorithm 3 of Athey, Imbens, Qu, and Viviano (2025). Select
this option to reproduce the paper's reported standard errors exactly.

{pmore}
The two choices differ by a factor of {cmd:B / (B - 1)} inside the
variance (equivalently, {cmd:sqrt(B / (B - 1))} inside the SE), which is
below 0.5% when {it:B} = 200. Percentile confidence bounds are unaffected.
The chosen denominator is echoed in {cmd:e(bsvariance)}.

{phang}
{opt bsalpha(#)} is a deprecated alias for the significance level
{cmd:alpha = 1 - level()/100}.  It is retained for backward compatibility.
When specified, {opt bsalpha()} overrides {opt level()} and a note is
printed at estimation time.  New code should prefer {opt level()}.

{dlgtab:Covariates}

{phang}
{opth covariates(varlist)} specifies covariates to include in estimation
following the Equation 14 adjustment of Athey et al. (2025) Section 6.2.
Covariates enter the alternating minimisation as an additional WLS step that
updates a gamma coefficient vector.  All specified variables must be numeric
and must not contain missing values in the estimation sample.  The covariate
variables must not overlap with the outcome or treatment variables.

{pmore}
Stored results: {cmd:e(gamma)} (1 x p matrix of covariate coefficients),
{cmd:e(n_covariates)} (scalar), {cmd:e(covariates)} (macro listing the
covariate variable names).

{pmore}
Example: {cmd:trop y d, panelvar(id) timevar(t) covariates(x1 x2 x3)}

{dlgtab:Survey Design}

{phang}
{opth strata(varname)} specifies the stratification variable for Rao-Wu
bootstrap variance estimation.  Required when {opt psu()} or {opt fpc()} is
specified.

{phang}
{opth psu(varname)} specifies the primary sampling unit variable.  Required
when {opt strata()} is specified.

{phang}
{opth fpc(varname)} specifies the finite population correction variable.
Optional; when supplied, the Rao-Wu bootstrap incorporates the sampling
fraction adjustment.

{phang}
{opt nest} requests that PSUs be nested within strata (relevant when PSU
identifiers are not globally unique).

{phang}
{opt singleunit(centered|skip)} specifies the strategy for handling strata
containing a single primary sampling unit (lonely PSU) during Rao-Wu
bootstrap variance estimation.

{pmore}
{opt skip} (default) omits the lonely-PSU stratum from the bootstrap
variance contribution entirely.  This preserves backward compatibility with
pre-1.2 behaviour and is appropriate when the lonely stratum contributes
negligible variance.

{pmore}
{opt centered} uses the grand-mean centring correction: the single PSU's
contribution is computed relative to the overall weighted mean rather than
the within-stratum mean.  This is the Stata {cmd:svyset} convention for
{cmd:singleunit(centered)} and avoids discarding information from the
stratum.

{dlgtab:Other}

{phang}
{opt seed(#)} specifies the random number seed for reproducibility.
Default is {cmd:42}.

{phang}
{opt level(#)} specifies the confidence level for confidence intervals.
Default is {cmd:c(level)}, typically 95.

{phang}
{opt vlevel(#)} specifies the verbosity level for output control.
Five levels are available:

{phang2}{cmd:0} {hline 2} silent (no progress messages){p_end}
{phang2}{cmd:1} {hline 2} minimal (start/completion only){p_end}
{phang2}{cmd:2} {hline 2} detailed (LOOCV diagnostics; same as {opt verbose}){p_end}
{phang2}{cmd:3} {hline 2} debug (intermediate values){p_end}
{phang2}{cmd:4} {hline 2} trace (all internal steps){p_end}

{pmore}
Default is {cmd:0}.  When {opt verbose} is specified without {opt vlevel()},
the level is set to {cmd:2}.

{phang}
{opt verbose} displays detailed progress information including LOOCV
diagnostics, convergence status, and timing information.  Equivalent to
{cmd:vlevel(2)}.

{phang}
{opt notiming} suppresses the timing estimate display that {cmd:trop}
normally emits on large panels (N*T >= 50,000).  Use this when the
progress estimate is not wanted (e.g., in automated scripts).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Weight structures}

{pstd}
The two estimation methods use fundamentally different weight structures,
following Algorithm 2 and Remark 6.1 of the paper respectively.  The
{cmd:twostep} path is the paper's main estimator; {cmd:joint} is an
additional shared-weight restriction layered on top of the same TROP
ingredients:

{phang}
{bf:method(twostep)} — Per-observation weights (Eq. 3, Algorithm 2):{break}
Each treated observation (i,t) receives its own set of weights. Time weights
measure distance from the specific target period:
theta_s = exp(-lambda_time * |t - s|). Unit weights measure the RMSE
between each control unit j and the specific target unit i over common
control periods, excluding the target period t:
omega_j = exp(-lambda_unit * dist_{-t}(j, i)). This permits heterogeneous
treatment effects across units and periods.

{phang}
{bf:method(joint)} — Global weights (Remark 6.1):{break}
A single set of weights is shared across all treated observations. Time
weights measure distance to the center of the treated block:
delta_time[t] = exp(-lambda_time * |t - center|). Unit weights measure
the RMSE from each unit's pre-treatment trajectory to the average treated
trajectory: delta_unit[j] = exp(-lambda_unit * RMSE(j, avg_treated)).
This assumes homogeneous treatment effects, is computationally more
efficient, and is intended for panels where the treated units share the
same adoption window.

{pmore}
{bf:Note.} Paper Remark 6.1 defines the homogeneous-tau aggregation but
does not prescribe a specific time/unit kernel under the shared-weight
setting; the post-block midpoint and the pre-period trajectory RMSE used
above are {it:engineering choices} adopted by {cmd:trop}, not formulas
restated from the paper.  See "Methods and formulas" for the explicit
delta_time / delta_unit definitions.

{pstd}
{bf:When to use each method:}

{phang2}Use {opt twostep} (default) when treatment effects may vary across
units and time periods, or when the panel has complex treatment assignment
patterns.{p_end}

{phang2}Use {opt joint} when a single shared treatment effect and a common
treated block are substantively appropriate.{p_end}

{pstd}
{bf:Interpretation of e(mu)}

{pstd}
The content of {cmd:e(mu)} differs between estimation methods:

{phang}
{bf:method(twostep):} {cmd:e(mu)} is set to {cmd:.} (missing). The twostep
model is Y(0) = alpha_i + beta_t + L_{it} without an explicit global
intercept. Unit fixed effects are stored in {cmd:e(alpha)}.

{phang}
{bf:method(joint):} {cmd:e(mu)} returns the global intercept mu (a scalar).
The joint model is Y(0) = mu + alpha_i + beta_t + L_{it} with
identification constraints alpha_1 = beta_1 = 0.

{pstd}
Both parameterizations yield mathematically equivalent counterfactual
predictions.

{pstd}
{bf:Lambda grid comparison}

{col 5}Grid Style{col 20}lambda_time{col 35}lambda_unit{col 50}lambda_nn{col 62}Total
{col 5}{hline 65}
{col 5}default{col 20}6 values{col 35}6 values{col 50}5 values{col 62}180
{col 5}fine{col 20}7 values{col 35}7 values{col 50}7 values{col 62}343
{col 5}extended{col 20}14 values{col 35}16 values{col 50}19 values{col 62}4,256
{col 5}{hline 65}

{pstd}
The {opt extended} grid covers all optimal values from Table 2 of the paper:

{col 5}Dataset{col 25}lambda_unit{col 38}lambda_time{col 51}lambda_nn
{col 5}{hline 60}
{col 5}CPS log-wage{col 25}0{col 38}0.1{col 51}0.9
{col 5}CPS urate{col 25}1.6{col 38}0.35{col 51}0.011
{col 5}PWT{col 25}0.3{col 38}0.4{col 51}0.006
{col 5}Germany{col 25}1.2{col 38}0.2{col 51}0.011
{col 5}Basque{col 25}0{col 38}0.35{col 51}0.006
{col 5}Smoking{col 25}0.25{col 38}0.4{col 51}0.011
{col 5}Boatlift{col 25}0.2{col 38}0.2{col 51}0.151
{col 5}{hline 60}


{marker survey_weights}{...}
{dlgtab:Survey weights}

{pstd}
{cmd:trop} accepts {cmd:pweight} (probability / sampling weights) to support
survey-design-aware ATT aggregation.  When {cmd:[pweight=}{it:wgt}{cmd:]} is
supplied, the per-cell treatment effects are aggregated with a weighted mean:

{p 8 8 2}
ATT_hat = sum_{it: W=1} w_i * tau_{it} / sum_{it: W=1} w_i

{pstd}
where {it:w_i} is the pweight attached to unit {it:i}.  The pweight variable
must be strictly positive and {it:constant within each panel unit}; a cell-
varying weight triggers a hard error (r(459)).

{pstd}
Scope of the weighted path:

{phang}
- ATT aggregation and the bootstrap empirical distribution use the weighted
mean.  Each bootstrap draw inherits the original pweight of every resampled
unit.

{phang}
- The nuisance-parameter fits (alpha, beta, L) and the LOOCV objective
Q(lambda) remain unweighted.  This mirrors the design-based construction:
the cross-validation score is an in-sample prediction criterion that does
not depend on the target population.

{phang}
- Only pweights are supported.  {cmd:aweight}, {cmd:fweight}, and
{cmd:iweight} are rejected (r(101)).  Bootstrap inference is {it:pweight-
only} — strata, PSU, and finite-population-correction Rao-Wu resampling are
not implemented.

{phang}
- Running with {cmd:[pweight=1]} reproduces the unweighted output to
machine precision; this is a regression-test guarantee.

{pstd}
Stored metadata: {cmd:e(weight_var)} records the pweight variable name,
{cmd:e(wtype)} is set to {cmd:pweight}, and {cmd:e(wexp)} is {cmd:= }{it:wgt}.
{cmd:trop_bootstrap} re-reads these e() entries to dispatch the weighted
bootstrap path automatically.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup: Generate test panel data}

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 1000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/10)}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}
{phang2}{cmd:. gen y = rnormal() + 0.5*(id>80)*(t>7)}{p_end}
{phang2}{cmd:. gen d = (id > 80 & t > 7)}{p_end}

{pstd}
{bf:Quick start (fixed lambda, runs in seconds)}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) fixedlambda(0.5 1.0 0.1) seed(42)}{p_end}

{pstd}
{it:Use {cmd:fixedlambda()} to bypass LOOCV and get immediate results.
Recommended for first-time exploration and large panels.}

{pstd}
{bf:Twostep method with LOOCV (default)}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42)}{p_end}

{pstd}
{it:Note: LOOCV hyperparameter search can be slow on large panels.
Consider {cmd:fixedlambda()} or use a custom {cmd:lambda_nn_grid()}
that avoids the (0, 0.1) region for faster convergence.}

{pstd}
{bf:Joint method}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) seed(42)}{p_end}

{pstd}
{it:Use this only when a single shared treatment effect and a common
treated block are substantively appropriate.}

{pstd}
{bf:Joint method with exhaustive LOOCV (guaranteed grid argmin)}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) joint_loocv(exhaustive) seed(42)}{p_end}

{pstd}
{bf:With bootstrap inference}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) bootstrap(200) seed(42)}{p_end}

{pstd}
{bf:Using extended grid for finer search}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) grid_style(extended) seed(42)}{p_end}

{pstd}
{bf:Custom lambda grid}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) lambda_nn_grid(0 0.1 1e10) seed(42)}{p_end}

{pstd}
{bf:Fixed lambda (skip LOOCV)}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) fixedlambda(0.5 1.0 0.1) seed(42)}{p_end}

{pstd}
{bf:Verbose output}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42) verbose}{p_end}

{pstd}
{bf:Row-labelled fixed effects}

{pstd}
{cmd:e(alpha)} and {cmd:e(beta)} carry the sorted unique values of
{it:panelvar} / {it:timevar} as matrix row names, so the fixed effects
can be read directly against their original identifiers:

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42)}{p_end}
{phang2}{cmd:. matrix list e(alpha)              // rows: _1, _2, ... (numeric IDs get a leading underscore)}{p_end}
{phang2}{cmd:. matrix list e(beta)               // rows: time labels (e.g. _1989, _1990, ...)}{p_end}

{pstd}
{bf:Postestimation diagnostics}

{pstd}
After {cmd:trop}, the companion command {help trop_estat:{bf:estat}}
exposes thirteen diagnostics including hyperparameter sensitivity,
variance-covariance display, event-study analysis, pre-trend testing,
and a triple-robustness bias decomposition anchored to paper Theorem 5.1:

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. estat summarize                   // sample + treatment overview}{p_end}
{phang2}{cmd:. estat loocv                       // hyperparameter search trace}{p_end}
{phang2}{cmd:. estat weights                     // unit / time weight distribution}{p_end}
{phang2}{cmd:. estat factors                     // SVD of the factor matrix L}{p_end}
{phang2}{cmd:. estat bootstrap                   // bootstrap distribution summary}{p_end}
{phang2}{cmd:. estat sensitivity                 // LOOCV grid sensitivity summary}{p_end}
{phang2}{cmd:. estat vce                         // variance-covariance display}{p_end}
{phang2}{cmd:. estat triplerob                   // Theorem 5.1 bias decomposition}{p_end}

{pstd}
{bf:Per-cell treatment effects via {cmd:e(tau_matrix)}}

{pstd}
{cmd:e(tau_matrix)} is a {it:T x N} matrix indexed by (time, panel) with
treatment effects in treated cells and Stata missing ({cmd:.}) elsewhere.
Use it to retrieve tau by coordinate or to aggregate effects by row/column:

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42)}{p_end}
{phang2}{cmd:. matrix tauM = e(tau_matrix)         // T x N panel-shaped tau}{p_end}
{phang2}{cmd:. di "tau at (t=8, i=85) = " tauM[8, 85]}{p_end}

{pstd}
Average treatment effect within each post-treatment period (event-time path):

{phang2}{cmd:. mata: tau = st_matrix("e(tau_matrix)")}{p_end}
{phang2}{cmd:. mata: present = (tau :< .)                       // 1 if treated cell}{p_end}
{phang2}{cmd:. mata: att_t = rowsum(editmissing(tau, 0)) :/ rowsum(present)}{p_end}
{phang2}{cmd:. mata: att_t                                       // T x 1 (missing for pre-treatment rows)}{p_end}


{pstd}
{bf:{hline 70}}
{bf:Bundled Datasets}
{bf:{hline 70}}

{pstd}
The {cmd:trop} package ships six panel datasets.  After installing from
SSC, download them once into your working directory with {cmd:net get}:

{phang2}{cmd:. net get trop}{p_end}

{pstd}
This places the six {cmd:.dta} files in the current directory, ready to
{cmd:use}:

{col 5}Dataset{col 30}Source{col 55}N{col 60}T{col 65}Treatment
{col 5}{hline 70}
{col 5}{cmd:cps_logwage.dta}{col 30}CPS log-wage (min wage){col 55}50{col 60}40{col 65}real
{col 5}{cmd:cps_urate.dta}{col 30}CPS urate (min wage){col 55}50{col 60}40{col 65}real
{col 5}{cmd:pwt_loggdp.dta}{col 30}PWT log-GDP (democracy){col 55}111{col 60}48{col 65}real
{col 5}{cmd:germany_gdp.dta}{col 30}Abadie (2003) West Germany{col 55}17{col 60}44{col 65}{bf:d=0}
{col 5}{cmd:basque_gdp.dta}{col 30}Abadie (2003) Basque Country{col 55}18{col 60}43{col 65}{bf:d=0}
{col 5}{cmd:smoking_packs.dta}{col 30}California Prop 99{col 55}39{col 60}31{col 65}{bf:d=0}
{col 5}{hline 70}

{pstd}
{bf:Important:} {cmd:germany_gdp}, {cmd:basque_gdp}, and {cmd:smoking_packs}
have {cmd:d = 0} throughout.  They are raw outcome panels designed for
semi-synthetic simulation (as in Athey et al. 2025, Table 1).  You must
assign a treatment indicator before running {cmd:trop}.  See Example 4
below for a worked demonstration.


{pstd}
{bf:{hline 70}}
{bf:Complete Data Analysis Examples}
{bf:{hline 70}}

{pstd}
The following four examples demonstrate end-to-end workflows using real
and simulated panel data.  The bundled datasets are downloaded once with
{cmd:net get trop} (see above) and then loaded with {cmd:use}.  As a
convenience, {cmd:trop_data} {it:name} downloads and loads a single
dataset in one step (used in Example 1 below).


{pstd}
{bf:Example 1: CPS wage data {hline 2} basic twostep (local) analysis}

{pstd}
This example reproduces part of the paper's Table 1 analysis of minimum
wage effects on log wages across U.S. states.  The CPS dataset contains
50 states observed from 1979 to 2018; 8 states are treated at t=2018.
The outcome variable {cmd:y} is the log average weekly wage.

{phang}{it:Step 1: Download example datasets (one-time, after installation)}{p_end}

{phang2}{cmd:. net get trop}{p_end}

{phang}{it:Load the CPS log-wage panel}{p_end}

{phang2}{cmd:. use cps_logwage.dta, clear}{p_end}

{pstd}
Alternatively, {cmd:trop_data cps_logwage} downloads and loads the
dataset in one step.

{phang}{it:Step 2: Estimate ATT using the twostep (local) method with bootstrap}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(twostep) bootstrap(200) seed(42)}{p_end}

{phang}{it:Step 3: Examine stored results}{p_end}

{phang2}{cmd:. ereturn list}{p_end}
{phang2}{cmd:. display "ATT = " e(att)}{p_end}
{phang2}{cmd:. display "SE  = " e(se)}{p_end}
{phang2}{cmd:. display "95%% CI: [" e(ci_lower) ", " e(ci_upper) "]"}{p_end}
{phang2}{cmd:. display "p-value = " e(pvalue)}{p_end}

{phang}{it:Step 4: Inspect selected hyperparameters}{p_end}

{phang2}{cmd:. display "lambda_time = " e(lambda_time)}{p_end}
{phang2}{cmd:. display "lambda_unit = " e(lambda_unit)}{p_end}
{phang2}{cmd:. display "lambda_nn   = " e(lambda_nn)}{p_end}

{phang}{it:Step 5: Postestimation diagnostics}{p_end}

{phang2}{cmd:. estat summarize}{p_end}
{phang2}{cmd:. estat loocv}{p_end}
{phang2}{cmd:. estat bootstrap}{p_end}

{pstd}
{bf:Interpretation.}  The ATT estimates the average treatment effect on
the treated (paper Eq. 1): the mean counterfactual-adjusted impact of
the policy change on log wages for the 8 treated states in t=2018.
A positive ATT implies the treatment raised wages relative to the
predicted no-treatment trajectory.  The three-way robust construction
(Theorem 5.1) ensures that the estimate remains valid even if the unit
weights, time weights, or the nuclear-norm model alone fail to fully
balance the treated and control groups.


{pstd}
{bf:Example 2: PWT GDP data {hline 2} joint (global) method with advanced options}

{pstd}
The Penn World Table dataset measures log GDP per capita across 111
countries from 1960 to 2007; 29 countries receive treatment at t=2007
(a simultaneous-adoption design).  The larger panel and common adoption
window make this an ideal setting for the {cmd:joint} estimator.

{phang}{it:Step 1: Load PWT data}{p_end}

{phang2}{cmd:. use pwt_loggdp.dta, clear}{p_end}
{phang2}{cmd:. summarize}{p_end}
{phang2}{cmd:. display "N_units = " r(N) / 48 " | T = 48 | Treated = 29"}{p_end}

{phang}{it:Step 2: Joint estimation with fixed lambda (paper Table 2 values)}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) fixedlambda(0.4 0.3 0.006) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. display "ATT (joint, fixed lambda) = " e(att)}{p_end}

{phang}{it:Step 3: Compare with LOOCV-selected lambda using fine grid}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) grid_style(fine) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. display "ATT (joint, fine grid LOOCV) = " e(att)}{p_end}
{phang2}{cmd:. display "Selected: lt=" e(lambda_time) " lu=" e(lambda_unit) " lnn=" e(lambda_nn)}{p_end}

{phang}{it:Step 4: Exhaustive vs. cycling LOOCV comparison}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) joint_loocv(exhaustive) seed(42)}{p_end}
{phang2}{cmd:. scalar att_exh = e(att)}{p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) joint_loocv(cycling) seed(42)}{p_end}
{phang2}{cmd:. scalar att_cyc = e(att)}{p_end}
{phang2}{cmd:. display "ATT difference (exhaustive - cycling) = " att_exh - att_cyc}{p_end}

{phang}{it:Step 5: Weight diagnostics}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. estat weights}{p_end}
{phang2}{cmd:. estat triplerob}{p_end}

{pstd}
{bf:Interpretation.}  The joint method assumes a homogeneous treatment
effect tau across all treated cells (Remark 6.1).  Because 29 countries
adopt simultaneously, the shared-weight construction is substantively
appropriate.  The {cmd:estat triplerob} decomposition shows whether the
triple-robustness property delivers bias reduction via unit balance,
time balance, or regression adjustment alone.  Comparing fixed lambda
(from the paper's Table 2) with LOOCV-selected lambda verifies that
the cross-validation procedure finds values close to the paper's optimal.


{pstd}
{bf:Example 3: Simulated data {hline 2} verification with known true effect}

{pstd}
This example constructs a panel with a known treatment effect (tau=2.0)
and demonstrates that {cmd:trop} recovers it accurately.  The simulation
illustrates the three-way robustness by showing convergence to the
true effect even under various model misspecification scenarios.

{phang}{it:Step 1: Generate a balanced panel with known DGP}{p_end}

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 2025}{p_end}
{phang2}{cmd:. local N_units = 30}{p_end}
{phang2}{cmd:. local T_periods = 20}{p_end}
{phang2}{cmd:. local N_treated = 5}{p_end}
{phang2}{cmd:. local T_treat = 16}{p_end}
{phang2}{cmd:. local true_tau = 2.0}{p_end}
{phang2}{cmd:. set obs `= `N_units' * `T_periods''}{p_end}
{phang2}{cmd:. gen id = ceil(_n / `T_periods')}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}

{phang}{it:Step 2: Build Y(0) = alpha_i + beta_t + L_{it} + noise}{p_end}

{phang2}{cmd:. gen alpha_i = id * 0.3}{p_end}
{phang2}{cmd:. gen beta_t  = t * 0.1}{p_end}
{phang2}{cmd:. gen L_it   = sin(id * 0.5) * cos(t * 0.3)}{p_end}
{phang2}{cmd:. gen epsilon = rnormal(0, 0.2)}{p_end}
{phang2}{cmd:. gen d = (id > `N_units' - `N_treated') & (t >= `T_treat')}{p_end}
{phang2}{cmd:. gen y = alpha_i + beta_t + L_it + epsilon + `true_tau' * d}{p_end}

{phang}{it:Step 3: Estimate with twostep method}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(twostep) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. display "True tau       = `true_tau'"}{p_end}
{phang2}{cmd:. display "Estimated ATT  = " e(att)}{p_end}
{phang2}{cmd:. display "Bias           = " e(att) - `true_tau'}{p_end}
{phang2}{cmd:. display "SE             = " e(se)}{p_end}
{phang2}{cmd:. display "Coverage: " cond(e(ci_lower) <= `true_tau' & `true_tau' <= e(ci_upper), "YES", "NO")}{p_end}

{phang}{it:Step 4: Repeat with joint method for comparison}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. display "Joint ATT      = " e(att)}{p_end}
{phang2}{cmd:. display "Joint Bias     = " e(att) - `true_tau'}{p_end}

{phang}{it:Step 5: Verify triple robustness with the bias decomposition}{p_end}

{phang2}{cmd:. trop y d, panelvar(id) timevar(t) bootstrap(200) seed(42)}{p_end}
{phang2}{cmd:. estat triplerob}{p_end}

{pstd}
{bf:Interpretation.}  With a known true_tau = 2.0, the estimated ATT
should be close to 2.0 and the 95%% confidence interval should cover it.
The bias decomposition ({cmd:estat triplerob}) reveals the three
components of Theorem 5.1:

{phang2}||Delta^u||_2 {hline 2} unit imbalance{p_end}
{phang2}||Delta^t||_2 {hline 2} time imbalance{p_end}
{phang2}||B||_* {hline 2} regression adjustment misspecification{p_end}

{pstd}
The TROP estimator is consistent if any one of these three quantities is
zero (Corollary 1).  In this simulated example, the true DGP satisfies
Y(0) = alpha_i + beta_t + L_{it}, so the nuclear-norm regression
adjustment is correctly specified (||B||_* approx 0), guaranteeing
consistency regardless of finite-sample weight imbalance.


{pstd}
{bf:Example 4: Basque GDP data {hline 2} semi-synthetic simulation (d=0 panel)}

{pstd}
The Basque Country GDP dataset (Abadie & Gardeazabal 2003) ships with
{cmd:d = 0} throughout because it is a raw outcome panel.  To replicate
the paper's Table 1 Monte Carlo exercise, you assign treatment randomly
or designate a specific unit as treated.  This example demonstrates both
approaches.

{phang}{it:Approach A: Treated-unit simulation (designate Basque Country)}{p_end}

{phang2}{cmd:. use basque_gdp.dta, clear}{p_end}
{phang2}{cmd:. tab d}{p_end}
{phang2}{cmd:. * All d=0 -- assign treatment to unit 17 (Basque Country) post-1970}{p_end}
{phang2}{cmd:. replace d = (id == 17) & (t >= 1970)}{p_end}
{phang2}{cmd:. tab d}{p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) fixedlambda(0.35 0 0.006) seed(42)}{p_end}
{phang2}{cmd:. display "ATT (Basque treated-unit) = " e(att)}{p_end}

{phang}{it:Approach B: Random treatment assignment (Table 1 design)}{p_end}

{phang2}{cmd:. use basque_gdp.dta, clear}{p_end}
{phang2}{cmd:. * Randomly assign 3 units as treated from t >= 1975}{p_end}
{phang2}{cmd:. set seed 2025}{p_end}
{phang2}{cmd:. bysort id: gen tag = (_n == 1)}{p_end}
{phang2}{cmd:. gen u = runiform() if tag}{p_end}
{phang2}{cmd:. bysort id (u): replace u = u[1]}{p_end}
{phang2}{cmd:. sort u}{p_end}
{phang2}{cmd:. egen rank = group(u)}{p_end}
{phang2}{cmd:. replace d = (rank <= 3) & (t >= 1975)}{p_end}
{phang2}{cmd:. drop tag u rank}{p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(twostep) fixedlambda(0.35 0 0.006) seed(42)}{p_end}
{phang2}{cmd:. display "ATT (random treatment) = " e(att)}{p_end}

{pstd}
{bf:Interpretation.}  Because the true treatment effect is zero (the
treatment was assigned artificially to a pre-existing observational
panel), the estimated ATT should be close to zero.  Systematic deviation
from zero indicates finite-sample bias.  The paper's Table 1 reports the
normalized RMSE across many such random draws to compare estimator
performance.  The {cmd:basque_gdp}, {cmd:germany_gdp}, and
{cmd:smoking_packs} datasets are all used this way.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:trop} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:e(att)}}ATT point estimate{p_end}
{synopt:{cmd:e(se)}}bootstrap standard error{p_end}
{synopt:{cmd:e(t)}}t statistic (att/se){p_end}
{synopt:{cmd:e(ci_lower)}}primary confidence interval lower bound; matches one of the three candidates below according to {cmd:e(cimethod)}{p_end}
{synopt:{cmd:e(ci_upper)}}primary confidence interval upper bound{p_end}
{synopt:{cmd:e(pvalue)}}two-sided p-value for the primary interval (t-based p-value when {cmd:e(cimethod)}=={cmd:percentile}){p_end}
{synopt:{cmd:e(df_r)}}degrees of freedom for the t-based reference distribution = max(1, N_1 - 1) where N_1 is the ever-treated unit count; missing when N_1 < 2{p_end}
{synopt:{cmd:e(ci_lower_t)}}t-wrap CI lower bound using SE and t(df_r){p_end}
{synopt:{cmd:e(ci_upper_t)}}t-wrap CI upper bound{p_end}
{synopt:{cmd:e(pvalue_t)}}two-sided p-value from the t-wrap{p_end}
{synopt:{cmd:e(ci_lower_normal)}}normal-wrap CI lower bound using SE and N(0,1){p_end}
{synopt:{cmd:e(ci_upper_normal)}}normal-wrap CI upper bound{p_end}
{synopt:{cmd:e(pvalue_normal)}}two-sided p-value from the normal-wrap{p_end}
{synopt:{cmd:e(ci_lower_percentile)}}bootstrap percentile CI lower bound (Algorithm 3 step 6){p_end}
{synopt:{cmd:e(ci_upper_percentile)}}bootstrap percentile CI upper bound{p_end}
{synopt:{cmd:e(mu)}}global intercept ({cmd:.} for twostep, scalar for joint){p_end}
{synopt:{cmd:e(lambda_time)}}selected or fixed lambda_time{p_end}
{synopt:{cmd:e(lambda_unit)}}selected or fixed lambda_unit{p_end}
{synopt:{cmd:e(lambda_nn)}}selected or fixed lambda_nn{p_end}
{synopt:{cmd:e(stage1_lambda_time)}}Stage-1 univariate argmin for lambda_time (paper Footnote 2; cycling LOOCV only, missing for exhaustive){p_end}
{synopt:{cmd:e(stage1_lambda_unit)}}Stage-1 univariate argmin for lambda_unit (paper Footnote 2; cycling LOOCV only){p_end}
{synopt:{cmd:e(stage1_lambda_nn)}}Stage-1 univariate argmin for lambda_nn (paper Footnote 2; cycling LOOCV only){p_end}
{synopt:{cmd:e(loocv_score)}}LOOCV objective Q(lambda_hat) = sum over (i,t) with W_{it}=0 and finite Y_{it} of tau_hat_{it}^loocv(lambda_hat)^2 (paper Eq. 5 restricted to observed control cells){p_end}
{synopt:{cmd:e(loocv_n_valid)}}number of successful LOOCV fits{p_end}
{synopt:{cmd:e(loocv_n_attempted)}}total LOOCV fit attempts (= every D=0 cell, paper Eq. 5){p_end}
{synopt:{cmd:e(loocv_fail_rate)}}LOOCV failure rate (0 to 1){p_end}
{synopt:{cmd:e(loocv_rmse)}}LOOCV root mean squared error = sqrt(Q(lambda_hat) / n_valid){p_end}
{synopt:{cmd:e(loocv_used)}}1 if LOOCV was performed, 0 if skipped{p_end}
{synopt:{cmd:e(loocv_first_failed_t)}}time index of the first LOOCV fit that failed (0-based; -1 if none){p_end}
{synopt:{cmd:e(loocv_first_failed_i)}}unit index of the first LOOCV fit that failed (0-based; -1 if none){p_end}
{synopt:{cmd:e(n_lambda_time)}}number of lambda_time grid values{p_end}
{synopt:{cmd:e(n_lambda_unit)}}number of lambda_unit grid values{p_end}
{synopt:{cmd:e(n_lambda_nn)}}number of lambda_nn grid values{p_end}
{synopt:{cmd:e(n_grid_combinations)}}total grid combinations{p_end}
{synopt:{cmd:e(n_grid_per_cycle)}}grid points per coordinate descent cycle{p_end}
{synopt:{cmd:e(effective_rank)}}effective rank of L (sum(s)/s[1]){p_end}
{synopt:{cmd:e(n_iterations)}}number of iterations{p_end}
{synopt:{cmd:e(converged)}}convergence indicator (1=yes, 0=no){p_end}
{synopt:{cmd:e(n_obs_estimated)}}successfully estimated observations (twostep){p_end}
{synopt:{cmd:e(n_obs_failed)}}failed observations (twostep){p_end}
{synopt:{cmd:e(N_units)}}number of panel units N{p_end}
{synopt:{cmd:e(N_periods)}}number of time periods T{p_end}
{synopt:{cmd:e(N_treated_units)}}number of ever-treated units N_1 (cluster count for Algorithm 3){p_end}
{synopt:{cmd:e(N_obs)}}total number of observations{p_end}
{synopt:{cmd:e(N_treat)}}treated unit-period cell count = sum(W=1) across the estimation sample; legacy alias of {cmd:e(N_treated_obs)}{p_end}
{synopt:{cmd:e(N_treated)}}length of {cmd:e(tau)} = successfully estimated treated cells; equals {cmd:e(N_treated_obs)} when every treated cell converges{p_end}
{synopt:{cmd:e(N_treated_obs)}}treated unit-period cell count = sum(W=1) across the estimation sample.  Each treated (i,t) cell contributes one tau; the ATT in Eq. 1 is a mean (or weighted mean under pweight) over these cells.  Distinct from {cmd:e(N_treated_units)} which counts unique ever-treated units.{p_end}
{synopt:{cmd:e(N_control)}}number of control observations (W=0){p_end}
{synopt:{cmd:e(N_control_units)}}number of never-treated units N_0{p_end}
{synopt:{cmd:e(T_treat_periods)}}number of periods with treatment{p_end}
{synopt:{cmd:e(bootstrap_reps)}}bootstrap replications requested{p_end}
{synopt:{cmd:e(n_bootstrap_valid)}}successful bootstrap iterations{p_end}
{synopt:{cmd:e(bootstrap_fail_rate)}}bootstrap failure rate (0 to 1); parallels {cmd:e(loocv_fail_rate)}.  An advisory note is printed when this exceeds 5%; exceeding 50% aborts with {cmd:rc=504}.  Missing when {cmd:bootstrap(0)}.{p_end}
{synopt:{cmd:e(alpha_level)}}significance level for CI{p_end}
{synopt:{cmd:e(level)}}confidence level (e.g., 95){p_end}
{synopt:{cmd:e(seed)}}random number seed used{p_end}
{synopt:{cmd:e(balanced)}}1 if panel is balanced, 0 otherwise{p_end}
{synopt:{cmd:e(miss_rate)}}fraction of missing observations{p_end}
{synopt:{cmd:e(min_pre_treated)}}minimum pre-treatment periods for treated units{p_end}
{synopt:{cmd:e(min_valid_pairs)}}minimum common control periods across pairs{p_end}
{synopt:{cmd:e(has_switching)}}1 if treatment switching detected{p_end}
{synopt:{cmd:e(max_switches)}}maximum treatment switches observed{p_end}
{synopt:{cmd:e(data_validated)}}1 if data validation passed{p_end}
{synopt:{cmd:e(time_min)}}minimum time period value{p_end}
{synopt:{cmd:e(time_max)}}maximum time period value{p_end}
{synopt:{cmd:e(time_range)}}range of time periods{p_end}
{synopt:{cmd:e(n_pre_periods)}}number of pre-treatment periods{p_end}
{synopt:{cmd:e(n_post_periods)}}number of post-treatment periods{p_end}
{synopt:{cmd:e(condition_number)}}condition number of the WLS design matrix; large values (>1e10) indicate ill-conditioning{p_end}
{synopt:{cmd:e(n_covariates)}}number of covariates (0 if none){p_end}
{synopt:{cmd:e(deff_weights)}}Kish design effect of pweights = N * sum(w_i^2) / (sum(w_i))^2; measures efficiency loss from unequal weighting.  Only stored when pweights are supplied.{p_end}
{synopt:{cmd:e(max_fh)}}maximum finite-population fraction f_h across strata (Rao-Wu bootstrap); only stored when survey weights are used{p_end}
{synopt:{cmd:e(n_high_fpc)}}number of strata where f_h > 0.5 (high FPC detection); only stored when survey weights are used{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (1x1, ATT){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix (1x1; bootstrap only){p_end}
{synopt:{cmd:e(alpha)}}unit fixed effects (N x 1).  Row names are the sorted unique values of {cmd:e(panelvar)} on the estimation sample (sanitised to valid Stata matrix identifiers), so {cmd:matrix list e(alpha)} reports the fixed effects keyed by the original panel identifier.  {cmd:twostep:} algorithmic mean across treated observations (Algorithm 2 step 2 fits a separate alpha^{{it:i,t}} for each treated cell; {cmd:e(alpha)} averages them); {cmd:joint:} single model estimate.  See {cmd:e(alpha_semantics)}.{p_end}
{synopt:{cmd:e(beta)}}time fixed effects (T x 1).  Row names are the sorted unique values of {cmd:e(timevar)} on the estimation sample (sanitised to valid Stata matrix identifiers).  {cmd:twostep:} algorithmic mean across treated observations (same convention as {cmd:e(alpha)}); {cmd:joint:} single model estimate.{p_end}
{synopt:{cmd:e(factor_matrix)}}low-rank factor matrix L (T x N).  {cmd:twostep:} algorithmic mean across treated observations; {cmd:joint:} single model estimate.{p_end}
{synopt:{cmd:e(tau)}}per-cell treatment effects (N_treated x 1); populated for both {cmd:twostep} and {cmd:joint}.  For {cmd:joint} the vector carries the single scalar tau replicated, so {cmd:mean(e(tau)) == e(att)} to machine precision in either method.{p_end}
{synopt:{cmd:e(tau_matrix)}}treatment effects arranged as a T x N panel-shaped matrix with Stata missing (.) in untreated cells; omitted when the underlying panel metadata is unavailable.{p_end}
{synopt:{cmd:e(converged_by_obs)}}convergence flag per treated cell (N_treated x 1; 1 = converged, 0 = hit {opt maxiter()}, -1 = solver error); {cmd:twostep} only.{p_end}
{synopt:{cmd:e(n_iters_by_obs)}}iteration count per treated cell (N_treated x 1); {cmd:twostep} only.{p_end}
{synopt:{cmd:e(theta)}}time weights (T x 1; twostep only){p_end}
{synopt:{cmd:e(omega)}}unit weights (N x 1; twostep only){p_end}
{synopt:{cmd:e(delta_time)}}global time weights (T x 1; joint only){p_end}
{synopt:{cmd:e(delta_unit)}}global unit weights (N x 1; joint only){p_end}
{synopt:{cmd:e(bootstrap_estimates)}}bootstrap ATT estimates (B x 1){p_end}
{synopt:{cmd:e(lambda_time_grid)}}lambda_time grid values searched{p_end}
{synopt:{cmd:e(lambda_unit_grid)}}lambda_unit grid values searched{p_end}
{synopt:{cmd:e(lambda_nn_grid)}}lambda_nn grid values searched{p_end}
{synopt:{cmd:e(gamma)}}covariate coefficients (1 x p; only when {opt covariates()} is specified){p_end}
{synopt:{cmd:e(lambda_grid)}}Cartesian product of lambda grids (K x 3){p_end}
{synopt:{cmd:e(cv_curve)}}LOOCV scores at grid points (K x 4){p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}"trop"{p_end}
{synopt:{cmd:e(cmdline)}}full command line as typed{p_end}
{synopt:{cmd:e(method)}}"twostep" or "joint"{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(treatvar)}}treatment variable name{p_end}
{synopt:{cmd:e(panelvar)}}panel variable name{p_end}
{synopt:{cmd:e(timevar)}}time variable name{p_end}
{synopt:{cmd:e(grid_style)}}grid style actually used: {cmd:default}, {cmd:fine}, {cmd:extended}, or {cmd:custom} when one or more lambda_*_grid() options override a preset dimension{p_end}
{synopt:{cmd:e(twostep_loocv)}}twostep LOOCV strategy: {cmd:cycling} or {cmd:exhaustive}{p_end}
{synopt:{cmd:e(joint_loocv)}}joint LOOCV strategy: {cmd:cycling} or {cmd:exhaustive}{p_end}
{synopt:{cmd:e(alpha_semantics)}}interpretation tag for {cmd:e(alpha)}/{cmd:e(beta)}/{cmd:e(factor_matrix)}: {cmd:obs_average} (twostep, averaged across treated cells) or {cmd:single_model} (joint){p_end}
{synopt:{cmd:e(treatment_pattern)}}treatment pattern detected{p_end}
{synopt:{cmd:e(vcetype)}}"Bootstrap" (with bootstrap){p_end}
{synopt:{cmd:e(bsvariance)}}bootstrap variance denominator actually used: {cmd:sample} (default, 1/(B-1)) or {cmd:paper} (Alg 3, 1/B){p_end}
{synopt:{cmd:e(cimethod)}}primary confidence-interval method selected by {opt cimethod()}: {cmd:percentile}, {cmd:t}, or {cmd:normal}.  When an explicit request was downgraded (e.g. {cmd:cimethod(percentile)} with {cmd:bootstrap(0)}), the trace is reported as {cmd:"percentile->t"}.{p_end}
{synopt:{cmd:e(estat_cmd)}}"trop_estat"{p_end}
{synopt:{cmd:e(title)}}"TROP Estimator"{p_end}
{synopt:{cmd:e(predict)}}"trop_p"{p_end}
{synopt:{cmd:e(weight_var)}}pweight variable name (empty when no {cmd:[pweight=]} was supplied); see {help trop##survey_weights:Survey weights}{p_end}
{synopt:{cmd:e(wtype)}}weight type tag; set to {cmd:pweight} when weights were supplied, otherwise empty{p_end}
{synopt:{cmd:e(wexp)}}weight expression as typed (e.g. {cmd:= wgt}); empty without weights{p_end}
{synopt:{cmd:e(covariates)}}space-separated list of covariate variable names (empty when none){p_end}
{synopt:{cmd:e(spec_string)}}specification string recording the estimation call parameters (method, lambda values, covariates) for reproducibility{p_end}
{synopt:{cmd:e(strata_var)}}stratification variable name (survey design only){p_end}
{synopt:{cmd:e(psu_var)}}PSU variable name (survey design only){p_end}
{synopt:{cmd:e(fpc_var)}}FPC variable name (survey design only){p_end}
{synopt:{cmd:e(bootstrap_type)}}bootstrap type: {cmd:standard} or {cmd:rao_wu}{p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
The TROP estimator predicts counterfactual outcomes for treated unit-time
pairs using a working model Y_{it}(0) = alpha_i + beta_t + L_{it}, where
alpha_i are unit fixed effects, beta_t are time fixed effects, and L is a
low-rank factor component.

{pstd}
Unless otherwise noted, the formulas in this section describe the
{cmd:twostep} estimator, which is the paper's main Algorithm 2 path.  The
{cmd:joint} option replaces the cell-specific tau_{it} fits with a single
shared tau under the homogeneous-effect restriction of Remark 6.1.

{pstd}
For each treated observation (i,t), the parameters are estimated by solving
a weighted nuclear-norm penalized regression (Eq. 2):

{p 8 8 2}
(alpha_hat, beta_hat, L_hat) = argmin_{alpha,beta,L} sum_{j,s}
theta_s^{i,t} * omega_j^{i,t} * (1-W_{js}) *
(Y_{js} - alpha_j - beta_s - L_{js})^2 + lambda_nn * ||L||_*

{pstd}
where ||L||_* denotes the nuclear norm of L.  The weights are defined as
exponential distance-decay functions (Eq. 3):

{p 8 8 2}
theta_s^{i,t} = exp(-lambda_time * |t - s|)

{p 8 8 2}
omega_j^{i,t} = exp(-lambda_unit * dist_{-t}(j, i))

{pstd}
The unit distance is the RMSE between the outcome trajectories of units j
and i over common control periods, excluding the target period t:

{p 8 8 2}
dist_{-t}(j, i) = sqrt( sum_u 1{u!=t}(1-W_{iu})(1-W_{ju})(Y_{iu}-Y_{ju})^2
/ sum_u 1{u!=t}(1-W_{iu})(1-W_{ju}) )

{pstd}
The treatment effect for each treated observation (i,t) is estimated as:

{p 8 8 2}
tau_hat_{it} = Y_{it} - alpha_hat_i - beta_hat_t - L_hat_{it}

{pstd}
The ATT is the simple average of individual treatment effects over all
treated unit-time pairs (paper Eq. 1 / Algorithm 2 step 6):

{p 8 8 2}
tau_hat = (1 / sum_{i,t} W_{it}) * sum_{i,t} W_{it} * tau_hat_{it}

{pstd}
{bf:Joint method specifics (Remark 6.1).}  Under the homogeneous-treatment
restriction of paper Remark 6.1, {opt joint} replaces the cell-specific
fits with a single weighted least-squares problem over a shared weight
matrix delta = delta_time * delta_unit'.  Paper Remark 6.1 sketches the
aggregation but does {it:not} prescribe concrete time / unit kernels, so
{cmd:trop} adopts the following engineering choice (pinned by the released
numerical baseline):

{p 8 8 2}
delta_time[s] = exp(-lambda_time * |s - center|),
center = T - T_post / 2

{p 8 8 2}
delta_unit[j] = exp(-lambda_unit * RMSE_pre(j, avg_treated))

{pstd}
where {it:center} is the midpoint of the treated block, {it:T_post} is the
shared post-period count, and {it:RMSE_pre(j, avg_treated)} is the RMSE
of unit j's pre-treatment outcomes against the period-wise average treated
trajectory.  These distance definitions are a reasonable adaptation of
Eq. (3) to the shared-weight setting; the post-block midpoint and the
pre-period trajectory RMSE are specific engineering choices, not formulas
prescribed by the paper.  After fitting (mu, alpha, beta, L) by
weighted nuclear-norm regression with weight matrix delta * (1 - W), the
scalar tau_hat is recovered post-hoc as the weighted mean residual on
treated cells (paper Eq. 10 identity for the homogeneous-tau case).

{pstd}
The triple robustness property (Theorem 5.1) states that the bias satisfies:

{p 8 8 2}
|E[tau_hat - tau | L]| <= ||Delta^u||_2 * ||Delta^t||_2 * ||B||_*

{pstd}
where Delta^u is unit imbalance (the discrepancy between the weighted
average of control unit loadings and the treated unit loading), Delta^t is
time imbalance (the analogous discrepancy for time factor loadings), and B
captures regression adjustment misspecification.  The estimator is
consistent if any one of the three components is zero (Corollary 1):
(a) balance over unit loadings, (b) balance over factor loadings, or
(c) correct regression adjustment specification.

{pstd}
Tuning parameters (lambda_time, lambda_unit, lambda_nn) are selected via
leave-one-out cross-validation (LOOCV) minimizing (Eq. 5):

{p 8 8 2}
Q(lambda) = sum_{i,t} (1 - W_{it}) * (tau_hat_{it}(lambda))^2

{pstd}
The grid search uses coordinate descent (footnote 2 of the paper): each
parameter is optimized in turn while holding the other two at their current
optimal values.  In {cmd:trop}, this paper-style cycling search remains
available for both methods, while exhaustive Cartesian search is also
exposed as an engineering option when users prefer the exact grid argmin.

{pstd}
Bootstrap variance estimation follows Algorithm 3: units are resampled
with replacement within the treated and control groups separately (paper
Alg 3 step 4), and the TROP estimator is recomputed on each bootstrap
sample holding the LOOCV-selected lambda_hat fixed (paper Alg 3 step 5;
strict re-LOOCV per draw is out of scope for the current release).

{pstd}
The paper writes the bootstrap variance as

{p 8 8 2}
V_hat_paper = (1/B) * sum_{b=1}^{B} (tau_hat^{(b)} - tau_bar)^2

{pstd}
By default {cmd:trop} reports the Bessel-corrected sample variance
instead, which is the unbiased estimator of the bootstrap variance and
matches the default inferential convention used by the package for
bootstrap SEs:

{p 8 8 2}
V_hat_trop = (1/(B-1)) * sum_{b=1}^{B} (tau_hat^{(b)} - tau_bar)^2

{pstd}
The denominator is user-selectable through {opt bsvariance(sample|paper)}:
the default {cmd:sample} uses {cmd:1/(B-1)} and matches V_hat_trop, while
{cmd:paper} uses {cmd:1/B} and reproduces V_hat_paper exactly. The two
choices differ by a factor B/(B-1) inside the variance (about 0.5% at the
default B = 200) and coincide as {it:B} grows; {cmd:e(bsvariance)} records
the active choice. tau_hat^{(b)} is the ATT estimate from the b-th
bootstrap sample, tau_bar is the mean of the bootstrap estimates, and the
bootstrap standard error {cmd:e(se)} is the square root of the selected
variance.  The percentile CI
{cmd:e(ci_lower_percentile)}/{cmd:e(ci_upper_percentile)} is taken from
the alpha/2 and 1-alpha/2 sample quantiles of the bootstrap distribution,
using linear interpolation between adjacent order statistics (the
(n-1)*p fractional-index convention) and is unaffected by the denominator
choice.


{marker implementation_notes}{...}
{title:Implementation notes}

{pstd}
The {cmd:trop} core is a precompiled Rust library invoked via a C plugin.
The numerical algorithm follows Athey, Imbens, Qu and Viviano (2025) Eq. 2
and Algorithms 1-3.  Several implementation choices that a careful reader
might want to inspect are listed below; each one is pinned by a regression
test so future refactors cannot silently regress.

{phang}
1. {bf:FISTA adaptive restart disabled} ({cmd:rust/src/estimation.rs}).  The
nuclear-norm proximal solver does {bf:not} use the monotone gradient-restart
scheme of O'Donoghue & Candes (2015).  Although the restart criterion can
eliminate momentum oscillations in theory, it fires too aggressively on
small panels and prevents convergence.  The reference Python implementation
does not use restart either, so it is disabled to maintain numerical
consistency.  Locked in by {cmd:tests/test_fista_restart_stability.do}.

{phang}
2. {bf:LAPACK dgelsd for the weighted least-squares step}
({cmd:rust/src/estimation.rs}).  The SVD-based minimum-norm solver
returns a Moore-Penrose pseudoinverse solution on rank-deficient
designs that arise when the weight vector zeroes out entire
rows/columns of the design matrix.  The SVD truncation tolerance
{cmd:rcond} is {cmd:max(eps * max(m, n), 1e-12)} — the 1e-12 floor
stabilises alpha-hat / beta-hat on the smallest benchmark panels
(Basque N=17, West Germany N=16) without perturbing tau-hat.
Locked in by {cmd:tests/test_dgelsd_rank_deficient_wls.do}.

{phang}
3. {bf:UnitDistanceCache} ({cmd:rust/src/distance.rs}).  The pairwise
Sum (Y_i - Y_j)^2 quantities are precomputed once; each leave-t-out
distance dist_{c -(}-t{c )-}(j, i) is then an O(1) subtraction instead
of an O(T) rescan.  Locked in by
{cmd:tests/test_unit_distance_cache_equivalence.do}.

{phang}
4. {bf:Deterministic LOOCV tie-breaker} ({cmd:rust/src/loocv.rs},
{cmd:better_candidate}).  When two (lambda_time, lambda_unit, lambda_nn)
triples score within TIE_TOL = 1e-10 of each other, {cmd:trop} prefers
the largest lambda_nn, then smallest lambda_time, then smallest
lambda_unit.  The 1e-10 threshold sits roughly 4 orders of magnitude
above the IEEE 754 double-precision epsilon (~2.2e-16) yet well below
typical finite LOOCV scores (Q ~ 1e-3 on the standard benchmarks), so
the tie-breaker activates only on genuine numerical ties.  Without it
ULP-level BLAS differences can flip {cmd:argmin Q(lambda)} across
platforms.  Locked in by {cmd:tests/test_loocv_tiebreak_determinism.do}.

{phang}
5. {bf:Inference reference distribution} ({cmd:ado/trop.ado},
{cmd:mata/trop_ereturn_store.mata}).  The bootstrap resamples units in
stratified fashion (Algorithm 3 step 3), so the cluster count that
governs the small-sample reference df is N_1, the number of
ever-treated units — not the number of treated cells.  {cmd:trop}
therefore uses {it:t}(N_1 - 1) whenever N_1 &gt;= 2 and falls back to
the standard normal otherwise.  The primary confidence interval
defaults to the paper-specified percentile interval whenever bootstrap
is enabled; the {opt cimethod()} option re-selects the primary pair
from the three candidates (percentile, t, normal).  Locked in by
{cmd:tests/test_inference_df_is_treated_units.do} and
{cmd:tests/test_cimethod_option.do}.

{pstd}
{bf:Scope exclusions} (paper-adjacent features that {cmd:trop} does not
implement): time-varying covariates X_{it}(t)*beta(t) where the coefficient
vector varies by period.  The current {opt covariates()} option implements
the time-invariant form from paper Section 6.2 Equation 14 where gamma is a
fixed p-vector.  Survey-weighted bootstrap with {opt strata()}/{opt psu()}/
{opt fpc()} is available since v1.2.0; switching-treatment patterns under
{opt method(joint)} remain out of scope.


{marker references}{...}
{title:References}

{phang}
Athey, S., G. W. Imbens, Z. Qu, and D. Viviano. 2025.
Triply robust panel estimators.
{it:arXiv preprint arXiv:2508.21536}.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Xuanyu Cai{break}
City University of Macau{break}
xuanyuCAI@outlook.com

{pstd}
Wenli Xu{break}
City University of Macau{break}
wlxu@cityu.edu.mo


{marker installation}{...}
{title:Installation}

{pstd}
{bf:From GitHub:}

{phang2}{cmd:. net install trop, from("https://raw.githubusercontent.com/gorgeousfish/TROP/main") replace}{p_end}

{pstd}
{bf:Local installation:}

{phang2}{cmd:. net install trop, from("/path/to/trop_stata") replace}{p_end}

{pstd}
{bf:Verify installation:}

{phang2}{cmd:. trop, version}{p_end}
{phang2}{cmd:. trop_check}{p_end}

{pstd}
The package includes precompiled plugins for macOS ARM64 (Apple Silicon),
macOS Intel (x86-64), and Windows x64.  No Rust toolchain is required for
these platforms.  See the project repository for build instructions if you
need to compile from source.


{marker alsosee}{...}
{title:Also see}

{psee}
Online: {helpb trop}, {helpb trop_estat}, {helpb trop_predict}
{p_end}
