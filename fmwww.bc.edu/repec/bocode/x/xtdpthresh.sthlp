{smcl}
{* *! version 0.7.9.1  02jul2026}{...}
{cmd:help xtdpthresh}
{hline}

{title:Title}

{pstd}
{hi:xtdpthresh} {hline 2} Dynamic panel threshold regression for unbalanced
panels, with endogenous regressors and continuity-robust inference


{title:Syntax}

{p 8 17 2}
{cmd:xtdpthresh} {it:depvar} [{it:indepvars}] {ifin}
{cmd:,} {cmdab:qx(}{it:varname}{cmd:)} [{it:options}]

{pstd}
where:

{pmore}
{it:depvar}    — dependent variable y{p_end}

{pmore}
{it:indepvars} — exogenous regressors (enter β and δ parts of the model){p_end}

{pmore}
{cmd:qx(}{it:varname}{cmd:)} — {bf:threshold variable} (REQUIRED; self-documenting style following xthreg2){p_end}


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt qx(varname)}}threshold variable (REQUIRED){p_end}
{synopt:{opt endo:genous(varlist)}}contemporaneously endogenous regressors; instrumented by lags from t-2{p_end}
{synopt:{opt pred:etermined(varlist)}}weakly exogenous (predetermined) regressors; instrumented by lags from t-1{p_end}
{synopt:{opt exo:genous(varlist)}}extra exogenous regressors (same treatment as {it:indepvars}){p_end}
{synopt:{opt iv(varlist[, collapse])}}additional user-supplied instruments.
The {cmd:collapse} sub-option collapses ONLY the user-IV block (one shared column per IV instead of one per time block); use top-level {cmd:collapse} to collapse everything. The {cmd:maxlag()} sub-option was removed in v0.7.5 — it never affected user IVs and silently overrode the top-level {cmd:maxlag()} (see Changes section).{p_end}
{synopt:{opt kink}}enforce continuity (kink) restriction{p_end}
{synopt:{opt static}}static model; do NOT auto-add L.{it:depvar} as regressor{p_end}
{synopt:{opt td}}purge common time shocks by within-time demeaning of y and regressors{p_end}
{synopt:{opt collapse}}collapse block-diagonal instruments across time (Roodman 2009); drastically reduces #instruments when T is large{p_end}
{synopt:{opt maxlag(# [#])}}restrict lag depth for instruments in the TRANSFORMED equation; {cmd:maxlag(L)} caps at lag L; {cmd:maxlag(a b)} uses lags a through b{p_end}
{synopt:{opt levmaxlag(# [#])}}lag range for level-equation IVs in {cmd:method(system)}; default {cmd:(1 1)} (Blundell-Bond convention); {cmd:levmaxlag(1 2)} uses Δy_{t-1} and Δy_{t-2}{p_end}

{syntab:Transformation and estimation}
{synopt:{opt method(fd|fod|system)}}panel transformation; default is {cmd:fd}{p_end}
{synopt:{opt grid(#)}}# grid points for γ search; default {cmd:30}{p_end}
{synopt:{opt trim(#)}}trim rate for γ grid (xthenreg convention); default {cmd:0.10}{p_end}

{syntab:Inference (Grid Bootstrap, Gong-Seo 2026)}
{synopt:{opt citype(grid|none)}}CI type for threshold; default {cmd:grid}.
Asymptotic CI not provided — the threshold estimator has a non-standard
limiting distribution (n^(1/4)-rate under continuity; Gong-Seo 2026 show
asymptotic CIs are invalid in that case). Use grid bootstrap instead.{p_end}
{synopt:{opt gridci(#)}}# grid points for CI construction; default {cmd:25}{p_end}
{synopt:{opt boot(#)}}bootstrap replications; default {cmd:299}{p_end}
{synopt:{opt rseed(#)}}set RNG seed before any bootstrap draw, for exact bit-for-bit reproducibility of CI bounds and test p-values{p_end}
{synopt:{opt nosearch}}skip grid bootstrap (point estimate only){p_end}
{synopt:{opt notest}}skip the linearity and continuity test bootstraps (independent of the CI); for coverage-only runs needing only {cmd:e(gamma_lo)}/{cmd:e(gamma_hi)}{p_end}
{synopt:{opt nowarn}}suppress CI-boundary pinning warning, disconnected-CI note, and the {cmd:method(system)} grid-bootstrap heuristic-extension advisory{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt verbose}}print per-γ bootstrap progress (25+ lines); default is a compact one-dot-per-γ progress bar{p_end}
{synopt:{opt exportgmm}}expose GMM moment weight A, instrument Z_f, and FD-transformed regressors X_f via persistent Mata externals for external verification (debug option){p_end}
{synoptline}

{p 4 6 2}
Use {help xtset} before running {cmd:xtdpthresh}.


{title:Description}

{pstd}
{cmd:xtdpthresh} estimates the dynamic panel threshold model of
Seo and Shin (2016), extended to unbalanced panels via Forward Orthogonal
Deviations (Arellano-Bover 1995) and System GMM (Blundell-Bond 1998).
Inference for the threshold location follows the grid-inversion framework
of Gong and Seo (2026, Section 4.1), implemented with the fast-bootstrap
scheme of {help xthenreg:xthenreg} (Seo, Kim, and Kim 2019): wild residual
weights, fixed first-stage GMM weight, one-step bootstrap per draw. See
{help xtdpthresh##citype:citype} for details and caveats.

{pstd}
For full methodology, Monte Carlo evidence, and worked empirical
illustrations on Hansen (1999) firm investment data and FDIC bank-panel
data, see the companion paper:
{browse "https://ssrn.com/abstract=6619058":Nguyen and Lai (2026)}.

{pstd}
The estimated dynamic model is:

{p 8 8 2}
{it:y_it = β1·y_{i,t-1} + x_it'β2 + (1, y_{i,t-1}, x_it')δ · 1(q_it > γ) + η_i + ε_it}

{pstd}
where {it:x_it} stacks the regressors listed in {it:indepvars} plus any
variables specified via {opt endogenous()} / {opt exogenous()}. The lagged
dependent variable {it:y_{i,t-1}} is appended automatically (the command is
dynamic by default; see {opt static} to disable). The coefficient vector δ
contains both the intercept jump (δ_1) and the regime-specific slope changes
for {it:y_{i,t-1}} and each element of {it:x_it}. In the static case
({opt static}), the term β1·{it:y_{i,t-1}} drops out of both the β and δ
blocks.

{pstd}
When the true model is continuous (satisfies δ_1 + δ_p·γ = 0 and δ_2:p-1 = 0),
the GMM threshold estimator converges at {it:n^(1/4)}-rate with a non-normal
distribution; the standard nonparametric bootstrap is inconsistent. The
grid bootstrap implemented here imposes the null at each candidate γ,
which is the key property that delivers empirical coverage near nominal
under both continuous (kink) and discontinuous (jump) specifications in
our Monte Carlo; see {help xtdpthresh##citype:citype} for the
implementation-level caveats.


{title:Changes in version 0.7.9.1 (02jul2026, since 0.7.5)}

{pstd}
Performance releases (v0.7.6-v0.7.9) plus one bug fix (v0.7.9.1). All
estimates, threshold CIs, test p-values, and {cmd:predict} series are
bit-for-bit identical to v0.7.5; only computation speed changed, plus one
new option.

{phang}
Bug fix (v0.7.9.1): on panels where an Arellano-Bond AR test cannot be
computed at all — e.g. AR(2) has zero lag-2 residual pairs when usable
observations span only two consecutive periods per unit (T=5 with the
dynamic model) — the command crashed with a Mata subscript error (3301)
after estimation had succeeded, returning nothing. It now reports the
affected AR statistic and its p-value as missing and returns all other
results normally. Present since v0.7.2, including the SSC v0.7.5.

{phang}
{cmd:notest} (new in v0.7.7) skips the linearity and continuity test
bootstraps while still constructing the threshold CI, for coverage-only
or simulation runs that need only {cmd:e(gamma_lo)}/{cmd:e(gamma_hi)}.

{phang}
Speedups (no result change): batched wild-bootstrap objective for the
grid CI and the linearity/continuity tests (v0.7.6-v0.7.7); large-N
cache build with preallocated stacking and run-based cluster moments
(v0.7.8); exact-guarded reuse of gamma-invariant work across the grid
(v0.7.9). Typically 10-40x faster for the bootstrap CI at large T /
{cmd:boot()}. The Mammen wild-bootstrap draw order is unchanged, so every
reported quantity matches v0.7.5 to machine precision.

{title:Changes in version 0.7.5 (11jun2026, since 0.6.0)}

{pstd}
Substantive consolidated release. Users upgrading from v0.6.x should
re-verify {cmd:method(system)} results (the new level-equation constant
changes them) and re-run AR(1)/AR(2) diagnostics (the AR statistic is now
the full Arellano-Bond formula).

{pstd}
{bf:Audit fixes (estimation).}

{phang}
{cmd:method(system)} estimates a level-equation constant ({cmd:cons_lvl},
the LAST element of {cmd:e(b)}) and adds the moment E[eta+eps] = 0, matching
{cmd:xtabond2}. Without it the level moments require E[dz] = 0, which fails
for trending instruments.

{phang}
Unified fixed-weight 2-stage grid search for {cmd:method(fod)} and
{cmd:method(system)}: previously the weight was re-estimated per grid point,
making the GMM objective not comparable across the grid.

{phang}
{cmd:e(sample)} is set via {cmd:esample()}; bootstrap p-values use the
Davidson-MacKinnon add-one correction (never exactly zero); empty or
disconnected CI acceptance regions are flagged via {cmd:e(ci_empty)} and
{cmd:e(ci_nseg)} instead of silently collapsing to a point; zero-instrument
rows are dropped in the transformed equation too.

{phang}
{cmd:iv(}{it:z}{cmd:, collapse)} now collapses ONLY the user-IV block; the
{cmd:iv(}{it:z}{cmd:, maxlag(...))} sub-option is removed and now errors
{cmd:r(198)} (it silently overrode the top-level {cmd:maxlag()} -- use that
instead). New {cmd:rseed(}{it:#}{cmd:)} for reproducibility; {cmd:e(cmdline)}
stored; per-gamma caches built once and shared across the grid search, CI,
and specification tests; Mata conformability fix in {cmd:xdpt2_stack_at_gamma}
that crashed {cmd:method(system)}.

{pstd}
{bf:B1 -- full Arellano-Bond AR formula (now VERIFIED).} AR(1)/AR(2) use
the full Arellano and Bond (1991, eq. 8) m-statistic
m_k = b0 / sqrt(T1 + T2 + T3), including the estimated-parameter variance
correction, with a principled fallback to the simplified b0/sqrt(T1) when
the variance pieces are unavailable or non-positive. The earlier
limitation (simplified statistic without the correction) is RESOLVED.
Certified two ways: (1) an independent external re-implementation of the
formula, fed the package's own A / Z_f / X_f / V / residuals (exposed via
{cmd:exportgmm}), reproduces {cmd:e(ar*)} to machine precision AND matches
Roodman's {cmd:abar} bit-for-bit on identical first-difference residuals;
(2) Monte Carlo size of the AR(2) test under an H0 data-generating process
is on target near the 5% nominal level.

{pstd}
{bf:Postestimation predict.} New {cmd:xtdpthresh_p} returns {cmd:residuals}
(the residual of the equation actually estimated), {cmd:arresiduals} (the
FD AR-test series the AR statistics consume, xtabond2 convention),
{cmd:xb}, and {cmd:regime}. Residuals are merged back from the persisted
estimation rows by ({it:panelvar},{it:timevar}) key -- identical by
construction across all methods and any panel pattern, guarded by
{cmd:e(p_serial)} against stale Mata state. See
{help xtdpthresh##postest:Postestimation}.

{pstd}
{bf:New e() scalars and option.} {cmd:e(ar*_b0)}, {cmd:e(ar*_T1)},
{cmd:e(ar*_TT)} expose the AR m-statistic decomposition; {cmd:e(ar*_np)}
the lag-pair count (sign flags the full vs fallback path). New
{cmd:exportgmm} option exposes the GMM weight A, instruments Z_f, and
FD-transformed regressors X_f via Mata externals for external verification.


{title:Syntax conventions relative to xthenreg}

{pstd}
{cmd:xtdpthresh} is designed to feel familiar to users of {cmd:xthenreg}
(Seo, Kim, and Kim 2019) while extending it along several dimensions. Key
differences:

{phang}
{cmd:*} Positional arguments are {bf:depvar [indepvars]}. The threshold
variable is passed via the REQUIRED option {cmd:qx(}{it:varname}{cmd:)},
not as a positional argument. This follows the self-documenting
convention of {cmd:xthreg2} (Wang-Lian 2019).

{phang}
{cmd:*} Added: {cmd:method()} for FD/FOD/System choice. {cmd:method(fd)}
is the default and reproduces {cmd:xthenreg}; {cmd:method(fod)} enables
unbalanced panel support; {cmd:method(system)} adds Blundell-Bond level
moments.

{phang}
{cmd:*} Two-step weight: {cmd:xtdpthresh} uses the UNCENTERED clustered
moment covariance (1/n)Σĝ_iĝ_i' (the {cmd:xtabond2} convention, keeping
Hansen J and AR diagnostics comparable to that command); {cmd:xthenreg}
centers it by subtracting the outer product of the mean moment, per
Seo-Shin (2016, eq. 11). Both are consistent under correct specification;
the difference is O(1/n). A {cmd:center} option is planned.

{phang}
{cmd:*} Coefficient SEs: {cmd:xtdpthresh} reports two-step cluster-robust
SEs for the slope parameters evaluated AT the estimated threshold —
treating γ̂ as fixed, the Hansen (1999) convention — and deliberately
reports NO asymptotic SE for γ̂ itself (its asymptotic distribution
depends on whether the model is continuous; Gong-Seo 2026). All inference
on γ runs through the grid-bootstrap CI instead. {cmd:xthenreg} reports a
joint variance including a kernel-estimated Jacobian column for γ, with
an SE for γ̂. Slope SEs from the two commands are of the same order in
the comparisons we ran.

{phang}
{cmd:*} Added: {cmd:iv(}{it:varlist}[, {cmd:collapse}]{cmd:)} for external
instruments. The {cmd:collapse} sub-option collapses ONLY the user-IV
block (one shared column per IV). The {cmd:maxlag()} sub-option that
existed in v0.6.x is removed in v0.7.5 — user IVs always enter as their
period-t value, so it never affected them. Use the top-level
{cmd:maxlag()} option for GMM-style instrument lag control.

{phang}
{cmd:*} Added: {cmd:collapse}, {cmd:maxlag()}, {cmd:levmaxlag()} for
xtabond2-style instrument count management — essential when T is
moderate and the Hansen J diagnostic would otherwise be unreliable.

{phang}
{cmd:*} Added: {cmd:citype()}, {cmd:gridci()}, {cmd:boot()}, {cmd:nosearch}
for grid bootstrap threshold CI (not in {cmd:xthenreg}).

{phang}
{cmd:*} Added: {cmd:td} to purge common time shocks by within-time
demeaning.

{phang}
{cmd:*} Added: {cmd:exogenous()} for explicit extra exogenous vars. In
practice, putting these in {it:indepvars} achieves the same effect.


{title:Options}

{dlgtab:Model specification}

{phang}
{opt endogenous(varlist)} specifies contemporaneously endogenous regressors,
i.e., E[x_{it} ε_{it}] ≠ 0. These are appended to the regressor matrix and
the command instruments them with lagged levels {x_{i,t-2}, x_{i,t-3}, ...}
in the transformed equation (lags from t-2, since x_{i,t-1} can correlate
with Δε_{it} = ε_{it} - ε_{i,t-1}). {it:endogenous()} variables must NOT
appear in {it:indepvars}, {opt exogenous()}, or {opt predetermined()}.

{phang}
{opt predetermined(varlist)} specifies weakly exogenous (predetermined)
regressors, i.e., E[x_{i,t-1} ε_{it}] = 0 but E[x_{it} ε_{it}] may be
nonzero. Predetermined regressors are instrumented with lagged levels
{x_{i,t-1}, x_{i,t-2}, ...} in the transformed equation — one more lag
than {opt endogenous()} since x_{i,t-1} is a valid instrument under the
predetermined assumption. This is the standard Arellano-Bond / Bond
(2002) classification: use {opt endogenous()} for variables jointly
determined with y_{it} (e.g., simultaneously chosen by the firm),
{opt predetermined()} for lagged-feedback variables (e.g., capital that
responds to past shocks but is fixed at time t). {it:predetermined()}
variables must NOT appear in {it:indepvars}, {opt exogenous()}, or
{opt endogenous()}.

{phang}
{opt exogenous(varlist)} specifies additional exogenous regressors. These
are treated identically to {it:indepvars} and included in Δx as IV. This
option is redundant with {it:indepvars} but provided for explicitness.

{it:Default instrument structure (iv() is OPTIONAL).} When {cmd:iv()} is
NOT specified, the command still builds a valid instrument matrix Z
automatically, per Arellano-Bond convention. Per time block t, Z contains:

{phang2}
(i) a constant column;

{phang2}
(ii) lags of the dependent variable y_{t-2}, y_{t-3}, ... (dynamic models);

{phang2}
(iii) for each exogenous regressor (listed in {it:indepvars} or
{opt exogenous()}): the contemporaneous Δx_t or x_t itself — exog vars
instrument themselves under E[x · ε]=0;

{phang2}
(iv) for each variable in {opt endogenous()}: its own lags x_{t-1},
x_{t-2}, ... as Arellano-Bond moment conditions.

{pstd}
So a minimal call like {cmd:xtdpthresh y x1 x2, qx(q)} already uses
x1, x2, and the lagged y as instruments — no need to specify {cmd:iv()}.

{phang}
{opt iv(varlist[, collapse])} specifies {it:additional} user-supplied
instruments that enter Z without being added as regressors. Useful when
an {it:external} IV exists (e.g., industry-level average that moves with
a firm endogenous variable). Each {it:iv} variable contributes one extra
column per time block. Under {cmd:method(system)}, user IVs are added to
BOTH transformed- and level-equation moment blocks — valid when the user
IV is exogenous in levels. User is responsible for supplying only IVs
satisfying E[z · ε] = 0 in levels.
The {cmd:collapse} sub-option (v0.7.0 semantics) collapses ONLY the user-IV
block — one shared column per IV across all time blocks. Use the top-level
{cmd:collapse} option to collapse everything. The {cmd:maxlag()} sub-option
that existed in v0.6.x is removed in v0.7.5 (it never affected user IVs);
use the top-level {cmd:maxlag()} for GMM-style instrument lag control.

{phang}
{opt kink} requests the continuity-restricted (kink) model of Seo-Shin
(2016). Under this restriction, the model is continuous at γ:
δ_2 = 0_{p-1} and δ_1 + δ_3·γ = 0. The threshold variable's slope changes
at γ, but no jump occurs. The coefficient vector has p+2 elements
(β_1, ..., β_p, kink_slope) instead of 2p+2 in the unrestricted (jump)
model.

{phang}
{opt static} specifies a static model. The default is dynamic, which
automatically includes L.{it:depvar} as a regressor. With {cmd:static},
L.{it:depvar} is not auto-added; users must include any lag explicitly
in {it:indepvars}.

{phang}
{opt td} purges common time shocks by subtracting the cross-sectional
mean at each time period from {it:depvar}, {it:indepvars}, and variables
listed in {opt endogenous()}, {opt exogenous()}, and {opt iv()}. The
threshold variable {it:q} is left untouched so γ retains its original
scale and interpretation. Demeaning is applied after internal {cmd:preserve},
so user data is not modified permanently. This is the standard panel
econometrics approach to controlling for aggregate time effects (e.g.,
macroeconomic shocks); it is equivalent to including year dummies whose
coefficients are restricted to be equal across regimes.

{phang}
{opt collapse} collapses block-diagonal instruments across time periods
(Roodman 2009). By default, each moment (lag of y, Δx, endog lag, user
inst) gets a separate column per time block, causing the instrument
count to grow quadratically with T. With {cmd:collapse}, instruments
are stacked into a single shared column per lag depth, reducing the
total count by a factor of (T−2). Use this for long panels (T ≥ 10) to
mitigate instrument proliferation and produce reliable Hansen J tests.
Downside: weaker identification at each γ due to fewer moments.

{phang}
{opt maxlag(# [#])} restricts which lags are used as instruments,
analogous to xtabond2's {cmd:lag()} suboption.

{pmore}
{cmd:maxlag(L)} caps instrument lag depth at L (uses lags 1 through L
for endogenous variables; lags 2 through L+1 for the auto-added L.y).

{pmore}
{cmd:maxlag(a b)} uses lags a through b inclusive. For example,
{cmd:maxlag(2 4)} uses lags 2, 3, 4. Useful when short lags are
"too recent" to be valid IVs (possibly still correlated with ε).

{pmore}
Combine with {cmd:collapse} for aggressive instrument reduction:
{cmd:maxlag(2 4) collapse} yields few moments and reliable Hansen J
at the cost of identification strength. Monitor {cmd:e(N_iv)} to
ensure the model remains identified (N_iv ≥ # regressors).

{phang}
{opt levmaxlag(# [#])} controls lag depth for LEVEL-equation instruments
under {cmd:method(system)}. Default is {cmd:levmaxlag(1)} = single
lag (Blundell-Bond 1998 convention): Δy_{t-1} as IV for y_{t-1},
Δx_t for exog x, Δx_{t-1} for endog x. Specify {cmd:levmaxlag(1 2)}
to add Δy_{t-2} and corresponding second-lag differences for exog/endog.
Multiple level lags can improve efficiency under stationarity but are
typically redundant with transformed-equation moments. Use cautiously.

{dlgtab:Transformation and estimation}

{phang}
{opt method(fd|fod|system)} selects the panel transformation used for
moment conditions:

{pmore}
{cmd:fd} — first-difference (Arellano-Bond 1991). Requires strongly
balanced panel or near-balanced (gaps drop obs). Matches {cmd:xthenreg}
results.

{pmore}
{cmd:fod} — forward orthogonal deviations (Arellano-Bover 1995).
Recommended for unbalanced panels. Transforms each observation as a
weighted difference from the mean of future observations; preserves
observations whenever at least one future value exists.

{pmore}
{cmd:system} — system GMM (Blundell-Bond 1998). Stacks FOD equations
with level equations using Δ-lag instruments as in the {cmd:xtabond2}
FOD-plus-level configuration (Roodman 2009, Section 3.4).

{pmore}
{bf:CAUTION: method(system) should be used with care.} Formal asymptotic
theory for Blundell-Bond system GMM in dynamic panel threshold models
is not established in the literature, and the standard mean-stationarity
requirement on initial conditions must hold within each regime — a
non-trivial restriction when fixed effects are correlated with regime
membership. We recommend reporting {cmd:method(system)} results alongside
{cmd:method(fd)} or {cmd:method(fod)} as a robustness check rather than
as the primary specification.

{phang}
{opt grid(#)} sets the number of grid points for the γ search. Default 30.
For Monte Carlo or final estimation, use a denser grid (50-100).

{phang}
{opt trim(#)} sets the trimming rate for the γ grid, using xthenreg's
convention: {cmd:trim(#)} trims {it:#}/2 from each tail of {it:q_var}.
Examples: {cmd:trim(0.10)} → grid spans [p5, p95]; {cmd:trim(0.20)} →
grid spans [p10, p90]; {cmd:trim(0.40)} → grid spans [p20, p80]. Must
be in [0.01, 0.45]. Default 0.10. Note: this differs from {cmd:xthreg}
/{cmd:xthreg2} which interpret the trim argument as a per-tail fraction.

{dlgtab:Inference}

{phang}
{opt citype(grid|none)} chooses CI construction method for the threshold.

{pmore}
{cmd:grid} — grid bootstrap CI via test inversion within the framework
of Gong-Seo (2026, Section 4.1). Default.

{pmore}
{cmd:none} — skip threshold CI; report point estimate and coefficient SE
only.

{pmore}
Asymptotic CI is NOT provided as an option. Under the continuous (kink)
model, γ̂ is n^(1/4)-consistent with a non-normal limit distribution
(Theorem 2 of Gong-Seo 2026), making standard asymptotic intervals
invalid.

{pmore}
{bf:Implementation note.} The grid bootstrap follows the fast-bootstrap
scheme of {help xthenreg:xthenreg} (Seo, Kim, and Kim 2019, the reference Stata
implementation of Seo-Shin 2016): unit-level wild residual weights, a
fixed first-stage GMM weight matrix held across draws, and one-step
bootstrap GMM per replication. We use Mammen (1993) two-point wild
weights in place of the N(0,1) weights used by xthenreg (per
Davidson-MacKinnon 2000, for better finite-sample properties) and extend
the scheme from xthenreg's sup-Wald linearity test to (i) the grid-
inversion threshold CI of Gong-Seo (2026, Section 4.1) and (ii) the
continuity test of Gong-Seo (2026, Section 4.3, Theorem 7). The fast
scheme is 30-60 times faster than the exact Algorithm 1 of Gong-Seo and
matches user expectations from xthenreg, though Gong-Seo Theorem I.1
uniform validity is proved for the exact algorithm; Monte Carlo coverage
near nominal on the canonical Seo-Shin Tong-SETAR DGP supports the fast
scheme's empirical validity. A {cmd:bootstrap(exact)} option is planned
for a future version.

{phang}
{opt gridci(#)} sets grid points for CI construction. Finer grid gives
more precise CI but slower runtime. Default 25.

{pmore}
{bf:Implementation note.} CI construction uses {cmd:gridci(#)} points as
the H_0 grid (values of γ at which the test is inverted), but the
unrestricted argmin within each bootstrap replication is searched over
the coarser {cmd:grid(#)} points to save compute. The test-inversion
comparison is valid because the unrestricted argmin is computed on the
{it:same} coarse grid for both the sample statistic and the bootstrap
draws, so any coarseness-induced bias cancels in the quantile
comparison. For applications needing the finest possible unrestricted
search, set {cmd:grid(#)} equal to or larger than {cmd:gridci(#)}.

{phang}
{opt boot(#)} sets bootstrap replications. Minimum 10 (enforced for debugging
only; a warning is issued if {it:#} < 99). For valid 5% inference follow
Davidson and MacKinnon (2000, {it:Econometric Reviews}): 99+ is the minimum,
299-499 is recommended for production, 99-199 for exploratory runs.
Default 299.

{phang}
{opt nosearch} skips the grid bootstrap CI entirely. Equivalent to
{cmd:citype(none)}.

{phang}
{opt notest} skips the linearity and continuity test bootstraps only,
while still constructing the threshold CI. The two test bootstraps are
independent of the CI inversion, so this is useful for coverage or
simulation runs that need only {cmd:e(gamma_lo)} and {cmd:e(gamma_hi)}:
{cmd:e(pval_lin)} and {cmd:e(pval_cont)} are left missing. CI bounds are
bit-for-bit identical to a full run with the same {cmd:rseed()}.

{phang}
{opt nowarn} suppresses the CI-boundary pinning warning. By default,
{cmd:xtdpthresh} prints a warning when either CI bound equals the trim
floor/ceiling (within 10^-4 of the trim range). Boundary pinning signals
either weak identification in the affected regime or that the grid edge
at the current {cmd:trim()} setting cuts close to γ̂. The flag is stored
in {cmd:e(boundary_warn)} (0 = no pin, 1 = lower, 2 = upper, 3 = both)
regardless of whether {cmd:nowarn} is set. Use {cmd:nowarn} when running
many specifications in a loop to avoid log clutter.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level. Default 95.

{phang}
{opt verbose} prints per-γ progress during the grid bootstrap (one line
per γ point, 25+ lines of output). Useful for monitoring long-running
bootstraps on large panels or for debugging convergence. Without
{opt verbose}, the command prints a compact one-dot-per-γ progress bar.

{phang}
{opt exportgmm} populates the Mata externals {bf:xdpt_best_A} (GMM moment
weight, k_iv × k_iv), {bf:xdpt_best_Z_f} (instrument matrix on the FD-row
stack, n_trans × k_iv), and {bf:xdpt_best_X_f} (FD-transformed regressors
on the same rows, n_trans × k_W). Off by default — Z_f can be 4 MB+ on
balanced Hansen FD with maxlag(2 4). Use this when you want to verify the
AR(k) statistic externally: feed the externals plus
{cmd:predict, arresiduals} and {cmd:e(V)} into an independent
implementation of the Arellano-Bond (1991, eq. 8) formula and compare
against {cmd:e(ar*)}. See the v0.7.5 changelog for the example workflow.


{title:Examples}

{pstd}
Firm investment model with debt threshold, all regressors exogenous:

{phang2}{cmd:. xtset firm year}{p_end}
{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt) method(fd)}{p_end}

{pstd}
Same but with cashflow as endogenous (auto-lag instruments):

{phang2}{cmd:. xtdpthresh invest tobin_q, qx(debt)}{break}
{cmd:      endogenous(cashflow) method(fd)}{p_end}

{pstd}
Unbalanced banking panel, FOD transformation, with user-supplied IV:

{phang2}{cmd:. xtdpthresh roa gdp_growth, qx(car)}{break}
{cmd:      endogenous(credit_growth) iv(industry_avg_roa) method(fod)}{p_end}

{pstd}
xtabond2-style: lag range at top level, user-IV block independently collapsed inside {cmd:iv()}:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt)}{break}
{cmd:      iv(L2_tobin, collapse) maxlag(2 4) method(fd)}{p_end}

{pstd}
Point estimate only (skip bootstrap, useful for quick checks):

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt)}{break}
{cmd:      method(fd) nosearch}{p_end}

{pstd}
Full grid bootstrap with fine settings:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt)}{break}
{cmd:      method(fd) grid(50) gridci(40) boot(499) trim(0.10)}{p_end}

{pstd}
System GMM with dense instruments:

{phang2}{cmd:. xtdpthresh y x1 x2, qx(q)}{break}
{cmd:      endogenous(L.y) method(system) grid(40)}{p_end}

{pstd}
Kink (continuity-restricted) model; continuity test compares kink vs
jump:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt) method(fd) kink}{p_end}
{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt) method(fd)}{p_end}
{phang2}{cmd:. display "Continuity test p-value: " e(pval_cont)}{p_end}

{pstd}
The second call (unrestricted) reports {cmd:e(pval_cont)}; if less than
0.05, the jump model is preferred; otherwise kink is not rejected.


{marker postest}{...}
{title:Postestimation: predict}

{p 8 17 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 22 tabbed}{...}
{synopt:Default}{cmd:residuals}{p_end}
{synopt:{cmd:residuals}}residual of the ESTIMATED equation: FD residual under {cmd:method(fd)}, FOD residual under {cmd:method(fod)}, FD-restack residual under {cmd:method(system)} (level-equation residuals are not yet exposed){p_end}
{synopt:{cmd:arresiduals}}the FD residual series the AR(1)/AR(2) tests consume (xtabond2 convention, always FD-form). For {cmd:method(fd)} this equals {cmd:residuals}; for {cmd:method(fod)} it is the FD restack and differs from the FOD estimation residual in variance and pattern; for {cmd:method(system)} it equals {cmd:residuals}{p_end}
{synopt:{cmd:xb}}fit of whichever equation {cmd:residuals} corresponds to ({cmd:residuals + xb} = transformed depvar row-by-row){p_end}
{synopt:{cmd:regime}}regime indicator 1{c -(}q_it > γ̂{c )-} on raw rows within {it:if}/{it:in} (not restricted to e(sample)){p_end}

{pstd}
Use {cmd:arresiduals}, not {cmd:residuals}, to reproduce the reported
AR(1)/AR(2) statistics under {cmd:method(fod)}: the FOD estimation
residual has a different variance and a mechanical first-order
autocorrelation, so an AR test on it would not match the reported value.
Under {cmd:method(fd)} and {cmd:method(system)} the two coincide.

{pstd}
Both {cmd:residuals} and {cmd:arresiduals} are merged into the new
variable by ({it:panelvar}, {it:timevar}) key from data persisted in Mata
globals during estimation — identical by construction to the
estimation-time series, for every method and any panel pattern. No
transformation, trim, t-2 instrument-history, or zero-instrument filter
is re-derived in {cmd:predict}. Rows outside the estimator's row set
return missing.

{pstd}
{bf:Staleness.} {cmd:predict} requires {cmd:xtdpthresh} as the active
estimation AND its Mata state intact. After {cmd:mata: mata clear},
{cmd:discard}, a Stata restart, or {cmd:estimates restore} of a different
{cmd:xtdpthresh} run, re-run {cmd:xtdpthresh} first. The error path is
clean: rc 498 if the Mata globals are gone or the run-serial disagrees
with the current e(); rc 301 if e() comes from a build {bf:<} v0.7.3 that
never stored prediction rows.

{pstd}
Example — extract residuals after {cmd:method(fd)}:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow debt, qx(debt) method(fd) maxlag(2 4) nosearch}{p_end}
{phang2}{cmd:. predict double ehat, residuals}{p_end}
{phang2}{cmd:. predict byte regime_hat, regime}{p_end}

{pstd}
{cmd:arresiduals} enables external verification of the AR(k) statistic
against {cmd:abar} or any reimplementation. With the AR-test residuals
available the user can reproduce v0.7.2's reported m_k bit-for-bit by
computing b0 = Σ_i Σ_t ê_{i,t}·ê_{i,t-k} and T1 = Σ_i (Σ_t
ê_{i,t}·ê_{i,t-k})² externally and comparing against {cmd:e(ar*_b0)} and
{cmd:e(ar*_T1)}; the full denominator {cmd:e(ar*_T1)} + {cmd:e(ar*_TT)}
accounts for the T2+T3 parameter-uncertainty correction (see B1 status
in {help xtdpthresh##changelog:Changes}).


{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used in GMM (= N_trans + N_level){p_end}
{synopt:{cmd:e(N_raw)}}raw sample size (rows after {it:touse}, before transformation){p_end}
{synopt:{cmd:e(N_trans)}}transformed rows (FD or FOD equations){p_end}
{synopt:{cmd:e(N_level)}}level equation rows (nonzero only for {cmd:method(system)}){p_end}
{synopt:{cmd:e(N_iv)}}number of instruments (columns of Z after dropping zero cols){p_end}
{synopt:{cmd:e(N_units)}}number of panel units used{p_end}
{synopt:{cmd:e(hansen)}}Hansen J over-identification statistic{p_end}
{synopt:{cmd:e(hansen_df)}}Hansen J degrees of freedom (N_iv − #params){p_end}
{synopt:{cmd:e(hansen_p)}}Hansen J p-value ({it:H}_0: moments valid){p_end}
{synopt:{cmd:e(ar1)}}Arellano-Bond AR(1) m-statistic{p_end}
{synopt:{cmd:e(ar1_p)}}AR(1) p-value (typically rejects for FD due to MA(1)){p_end}
{synopt:{cmd:e(ar2)}}Arellano-Bond AR(2) m-statistic{p_end}
{synopt:{cmd:e(ar2_p)}}AR(2) p-value (should NOT reject if moments valid){p_end}
{synopt:{cmd:e(ar1_b0)}}AR(1) numerator b0 = e_{-1}'·e (v0.7.2 debug scalar){p_end}
{synopt:{cmd:e(ar1_T1)}}AR(1) variance T1 = Σ_i c_i² (simplified denominator){p_end}
{synopt:{cmd:e(ar1_TT)}}AR(1) parameter-uncertainty term T2+T3 (full-formula correction){p_end}
{synopt:{cmd:e(ar2_b0)}}AR(2) numerator (debug scalar){p_end}
{synopt:{cmd:e(ar2_T1)}}AR(2) variance T1 (debug scalar){p_end}
{synopt:{cmd:e(ar2_TT)}}AR(2) parameter-uncertainty term T2+T3 (debug scalar){p_end}
{synopt:{cmd:e(ar1_np)}}AR(1) lag-pair count; >0 full AB path used, <0 simplified fallback{p_end}
{synopt:{cmd:e(ar2_np)}}AR(2) lag-pair count; sign = full/fallback path flag{p_end}
{synopt:{cmd:e(gamma)}}threshold point estimate γ̂{p_end}
{synopt:{cmd:e(gamma_lo)}}grid bootstrap CI lower bound (missing when {cmd:e(ci_empty)}=1){p_end}
{synopt:{cmd:e(gamma_hi)}}grid bootstrap CI upper bound (missing when {cmd:e(ci_empty)}=1){p_end}
{synopt:{cmd:e(ci_empty)}}1 if the bootstrap rejected every grid point (no CI), 0 otherwise{p_end}
{synopt:{cmd:e(ci_nseg)}}number of connected segments in the acceptance region (1 = standard CI; >1 = disconnected, hull reported){p_end}
{synopt:{cmd:e(pval_lin)}}linearity test p-value (Seo-Shin 2016 style; add-one corrected){p_end}
{synopt:{cmd:e(pval_cont)}}continuity test p-value (Gong-Seo 2026, Section 4.3 and Theorem 7; add-one corrected); missing when {cmd:kink} is set{p_end}
{synopt:{cmd:e(obj)}}GMM objective at γ̂{p_end}
{synopt:{cmd:e(k_exog)}}# exogenous regressors{p_end}
{synopt:{cmd:e(k_endog)}}# endogenous regressors{p_end}
{synopt:{cmd:e(k_predet)}}# predetermined regressors{p_end}
{synopt:{cmd:e(k_inst)}}# user-supplied instruments{p_end}
{synopt:{cmd:e(flag_kink)}}1 if kink option specified{p_end}
{synopt:{cmd:e(flag_static)}}1 if static option specified{p_end}
{synopt:{cmd:e(flag_td)}}1 if td option specified{p_end}
{synopt:{cmd:e(balanced)}}1 if panel is strongly balanced{p_end}
{synopt:{cmd:e(boundary_warn)}}grid-CI boundary-pin flag (0 none, 1 lower, 2 upper, 3 both){p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdpthresh}{p_end}
{synopt:{cmd:e(cmdline)}}the command line as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(q_var)}}name of threshold variable{p_end}
{synopt:{cmd:e(indepvars)}}names of exogenous regressors{p_end}
{synopt:{cmd:e(endog)}}names of endogenous regressors{p_end}
{synopt:{cmd:e(predet)}}names of predetermined regressors{p_end}
{synopt:{cmd:e(exog_extra)}}names of extra exogenous regressors (from {opt exogenous()}){p_end}
{synopt:{cmd:e(inst)}}names of user-supplied instruments{p_end}
{synopt:{cmd:e(method)}}transformation method used{p_end}
{synopt:{cmd:e(panelvar)}}panel variable name{p_end}
{synopt:{cmd:e(timevar)}}time variable name{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (β, δ){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}


{title:Coefficient labels}

{pstd}
The coefficient vector {cmd:e(b)} is labeled following {cmd:xthenreg}
convention.

{pstd}
{bf:Unrestricted (jump) model} — 2K+1 coefficients (2K+2 under {cmd:method(system)}):

{phang2}{cmd:Lag_y_b}       coefficient on L.{it:depvar} in β (if dynamic){p_end}
{phang2}{cmd:<var>_b}       coefficient on {it:var} in β (β part){p_end}
{phang2}{cmd:cons_d}        intercept jump δ_1{p_end}
{phang2}{cmd:Lag_y_d}       coefficient on L.{it:depvar} in δ (if dynamic){p_end}
{phang2}{cmd:<var>_d}       coefficient on {it:var} in δ (δ part){p_end}
{phang2}{cmd:cons_lvl}      level-equation constant (LAST element; {cmd:method(system)} only; absorbs E[η], matching {cmd:xtabond2}, v0.7.0){p_end}

{pstd}
{bf:Kink (continuity-restricted) model} — K+1 coefficients:

{phang2}{cmd:Lag_y_b}       coefficient on L.{it:depvar} (if dynamic){p_end}
{phang2}{cmd:<var>_b}       coefficient on {it:var}{p_end}
{phang2}{cmd:kink_slope}    change in slope of threshold variable at γ (δ_3){p_end}


{title:Specification tests (reported automatically)}

{pstd}
{cmd:xtdpthresh} reports three standard dynamic panel GMM specification
tests after every estimation:

{phang}
{bf:Hansen J over-identification test}: {it:H}_0 = moment conditions are
valid. Statistic {cmd:e(hansen)} = n·ḡ'Ω̂⁻¹ḡ at θ̂ ~ χ²(df), where
df = N_iv − #params. Reject → moment misspecification. {it:Caveat:} under
instrument proliferation the test over-rejects (Roodman 2009). Apply
{cmd:collapse} or {cmd:maxlag()} and monitor whether rejection persists.

{phang}
{bf:Arellano-Bond AR(1) test}: {it:H}_0 = no first-order autocorrelation
in the transformed residuals. Statistic {cmd:e(ar1)} follows {it:N}(0,1)
asymptotically. For FD, AR(1) is expected to REJECT (by construction,
Δε has MA(1) structure); for FOD, both directions are possible.

{phang}
{bf:Arellano-Bond AR(2) test}: {it:H}_0 = no second-order autocorrelation.
{cmd:e(ar2)}. {bf:Should NOT reject at conventional levels.} Rejection
signals that moment conditions are invalid (ε_{t-2} correlated with ε_t),
and the GMM estimator is inconsistent.

{phang}
{bf:AR formula.} {cmd:xtdpthresh} implements the full Arellano-Bond
(1991, eq. 8) m-statistic on the first-difference residuals (or FD-restacked
residuals for {cmd:method(fod|system)}), {it:m}_k = b0 / sqrt(T1 + T2 + T3),
where b0 = ẽ_{-k}'·ê is the lag-aligned residual cross product (raw sum),
T1 = Σ_i c_i² is the simplified denominator (per-unit cross products
squared), T2 = −2g'(G'AG)^{-1}G'A·s is the moment-vector covariance with
θ̂, and T3 = g'V̂g is the direct θ̂-variance contribution; g = X_t'ẽ_{-k},
G = X_s'Z_s, A = the moment weight paired with the reported θ̂, and V̂ is
the reported variance of θ̂. The estimator-influence pieces are exposed
as e(ar*_b0), e(ar*_T1), e(ar*_TT), and the underlying residuals are
returned by {cmd:predict, residuals}; this enables external bit-for-bit
verification against {cmd:abar} or any reimplementation of the Arellano-Bond
formula (see {help xtdpthresh##postest:Postestimation}). The pre-v0.7.2
simplified statistic m_k = b0/sqrt(T1) is retained as a principled fallback
(T2=T3=0 special case) whenever the estimator pieces are unavailable or
push the variance estimate non-positive in small samples. For
{cmd:method(fod|system)}, the AR(k) test residuals are restacked into
first-differences (matching the {cmd:xtabond2} convention); T2/T3 use the
estimation-equation residuals/instruments/regressors. Benchmark against
{cmd:xtabond2} on linear DPD specifications gives a model-effect comparison
rather than a clean formula comparison — for the latter, use
{cmd:predict, residuals} followed by an external full-AB implementation
on the same residual series.

{title:Hypothesis tests (bootstrap-based, require citype(grid))}

{pstd}
{cmd:xtdpthresh} reports three specification tests when grid bootstrap
inference is enabled (default, {cmd:citype(grid)}):

{phang}
{bf:Threshold CI} (Gong-Seo 2026 §4.1): 100(1-α)% confidence interval
for γ constructed by test inversion. For each γ_ℓ in a grid, the null
γ = γ_ℓ is tested via the GMM distance statistic D_n(γ_ℓ); γ_ℓ is
accepted if D_n(γ_ℓ) ≤ (1-α)-quantile of bootstrap distribution D*_n.
The CI is the convex hull of accepted γ_ℓ. Uniformly valid regardless
of whether the model is continuous or discontinuous. Stored in
{cmd:e(gamma_lo)}, {cmd:e(gamma_hi)}.

{phang}
{bf:Linearity test} (Seo-Shin 2016): tests H0: δ = 0 (no threshold
effect). Sup-Wald statistic with wild bootstrap under H0. Unit-level
Mammen weights. Low p-value rejects linearity → threshold effect is
significant. Stored in {cmd:e(pval_lin)}.

{phang}
{bf:Continuity test} (Gong-Seo 2026, Section 4.3 and Theorem 7): tests H0: model is
continuous (kink) vs H1: discontinuous (jump). Test statistic
T_n = n·(Q̂_kink(θ̃) - Q̂_jump(θ̂)). Bootstrap p-value under kink DGP.
Low p-value rejects continuity → use the unrestricted (jump) model.
High p-value (> 0.10) supports the kink specification. Stored in
{cmd:e(pval_cont)}. Only computed when {cmd:kink} is NOT set (the test
compares unrestricted vs kink; it makes no sense under kink estimation).


{title:Notes and known limitations}

{pstd}
{cmd:*} {bf:Sample size}: the framework requires large n for reliable
inference. Gong-Seo (2026) Table 1 simulations use n ∈ {400, 800, 1600}.
With n < 100, both point estimation and CI show substantial finite-sample
variance (we verified this on invest.dta subsets: at n=50, both
{cmd:xtdpthresh} and {cmd:xthenreg} produce unstable γ̂ across different
50-firm subsets).

{pstd}
{cmd:*} {bf:FD vs FOD}: on balanced data, FD gives the same point estimate
as {cmd:xthenreg}. FOD identifies a potentially different threshold
because the moment structure differs; FOD's advantage is robustness to
unbalanced patterns (late entry, early exit, random missing).

{pstd}
{cmd:*} {bf:Grid bootstrap runtime}: scales roughly as
{it:gridci × boot × grid × n}. With the per-γ cache and the fixed
first-stage weight (Gong-Seo 2026 Algorithm 1), each bootstrap
replication is a single matrix-vector product. With default settings
{cmd:grid(30) gridci(25) boot(299)}, expect 3-10 minutes per call
for n = 500 (System GMM is slowest, FD fastest). For exploratory work
use {cmd:grid(15) gridci(10) boot(99)} or {cmd:nosearch}; for published
results use the defaults.

{pstd}
{cmd:*} {bf:Linearity test}: the p-value from {cmd:e(pval_lin)} uses a
wild bootstrap implementation of the sup-Wald test of Seo and Shin
(2016). Both {cmd:xtdpthresh} and {cmd:xthenreg} use bootstrap-based
critical values; finite-sample power is comparable when bootstrap reps
are set equal.

{pstd}
{cmd:*} {bf:Continuity test interpretation}: reject H0 (continuous) at
5% → evidence for jump model with discontinuous threshold. Fail to
reject → either model is truly continuous, OR sample is underpowered.
The test is based on Gong-Seo (2026, Section 4.3 and Theorem 7) and uses bootstrap under
the kink DGP; critical values depend on a non-standard limiting
distribution V_1 - V_2 + V_3.


{title:References}

{phang}
Nguyen, D. C., and N. D. Lai. 2026. {browse "https://ssrn.com/abstract=6619058":xtdpthresh: Dynamic panel threshold regression for unbalanced panels, with endogenous regressors and continuity-robust inference}. {it:SSRN Working Paper} 6619058.

{phang}
Arellano, M., and O. Bover. 1995. Another look at the instrumental
variable estimation of error-components models. {it:Journal of
Econometrics} 68: 29-51.

{phang}
Arellano, M., and S. Bond. 1991. Some tests of specification for panel
data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Blundell, R., and S. Bond. 1998. Initial conditions and moment
restrictions in dynamic panel data models. {it:Journal of Econometrics}
87: 115-143.

{phang}
Gong, W., and M. H. Seo. 2026. Bootstraps for dynamic panel threshold
models. {it:Journal of Econometrics} 253: 106153.

{phang}
Hansen, B. E. 1999. Threshold effects in non-dynamic panels: Estimation,
testing, and inference. {it:Journal of Econometrics} 93: 345-368.

{phang}
Hansen, B. E. 1999. The grid bootstrap and the autoregressive model.
{it:Review of Economics and Statistics} 81: 594-607.

{phang}
Seo, M. H., S. Kim, and Y.-J. Kim. 2019. Estimation of dynamic panel
threshold model using Stata. {it:Stata Journal} 19: 685-697.

{phang}
Seo, M. H., and Y. Shin. 2016. Dynamic panels with threshold effect and
endogeneity. {it:Journal of Econometrics} 195: 169-186.


{title:Authors}

{pstd}
Duy Chinh Nguyen{break}
School of Business, International University, Ho Chi Minh City, Vietnam{break}
Vietnam National University Ho Chi Minh City, Vietnam{break}
Email: {browse "mailto:ndchinh@hcmiu.edu.vn":ndchinh@hcmiu.edu.vn}{break}
ORCID: {browse "https://orcid.org/0000-0002-9157-9358":0000-0002-9157-9358}

{pstd}
Nhat Duy Lai (corresponding author){break}
Faculty of Finance and Accounting, Saigon University,{break}
273 An Duong Vuong St, Cho Quan Ward, Ho Chi Minh City, Vietnam{break}
Email: {browse "mailto:lnduy@sgu.edu.vn":lnduy@sgu.edu.vn}{break}
ORCID: {browse "https://orcid.org/0009-0008-5365-2893":0009-0008-5365-2893}


{title:Also see}

{psee}
Online: {help xtset}, {help xthenreg} (Seo, Kim, and Kim 2019), {help xtabond},
{help xtabond2} (Roodman 2009){p_end}
