{smcl}
{* *! version 0.9.24  16jul2026}{...}
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
{synopt:{opt td}}FWL-correct time effects: partial common-across-regime time dummies out of the stacked system (dY, every W(γ) column, every instrument), per γ{p_end}
{synopt:{opt collapse}}collapse block-diagonal instruments across time (Roodman 2009); drastically reduces #instruments when T is large{p_end}
{synopt:{opt maxlag(# [#])}}restrict lag depth for instruments in the TRANSFORMED equation; {cmd:maxlag(L)} caps at lag L; {cmd:maxlag(a b)} uses lags a through b -- NOTE: the unlimited default is a risky choice on long panels (instrument proliferation, weak Hansen, heavy bootstraps); prefer explicit {cmd:maxlag(1 3)} or {cmd:collapse}; an allocation safety gate rejects nominal designs above 5,000 IV columns or 50 million Z cells before zero-column pruning; an interval ending below lag 2 no longer errors outright in a dynamic model (v0.9.19) -- a note is printed and identification must come from exogenous/predetermined moments or external {cmd:iv()}, with the rank/conditioning gates failing closed otherwise{p_end}
{synopt:{opt levmaxlag(# [#])}}lag range for level-equation IVs in {cmd:method(system)}; default {cmd:(1 1)} (Blundell-Bond convention); {cmd:levmaxlag(1 2)} uses Δy_{t-1} and Δy_{t-2}{p_end}

{syntab:Transformation and estimation}
{synopt:{opt method(fd|fod|system)}}panel transformation; default is {cmd:fd}{p_end}
{synopt:{opt grid(#)}}# grid points for γ search; minimum 10, default {cmd:100} (xthenreg convention; the old default 30 could miss the criterion's basin entirely){p_end}
{synopt:{opt gridtype(type)}}grid placement: {cmd:uniform} (default) or {cmd:quantile} (empirical quantiles of q){p_end}
{synopt:{opt minregime(#)}}additional FLOOR on per-regime support counts at each candidate γ (combined as max with the default trim rule){p_end}
{synopt:{opt gridsample(type)}}support for trim/quantile grids: {cmd:effective} (default; observations entering the effective criterion) or {cmd:observed} (current-row q, closer to xthenreg){p_end}
{synopt:{opt refine(#)}}0 to 20 local refinement iterations (default 0 = off): the observed q support values between γ̂'s two grid neighbors are appended to the grid and the two-stage search re-runs, so γ̂ lands on observed split points near the optimum; the coarse grid() is otherwise a finite approximation. Off by default so results stay grid()-comparable. Jump-only ({cmd:kink} is rejected: its threshold regressor varies continuously in γ); the restricted kink search inside the continuity diagnostic likewise remains a finite-grid approximation even when the jump search is refined{p_end}
{synopt:{opt boottype(type)}}threshold-CI bootstrap: {cmd:wild} (default; fast cluster wild residual scheme) or {cmd:unit} (EXPERIMENTAL unit-multiplicity resampling oriented at Gong-Seo Alg. 1 -- unrestricted-residual DGP, fixed sample first-stage weight, per-draw recentered Omega/W2* -- but NOT certified as the exact algorithm; {cmd:method(fd)} without {cmd:kink} or {cmd:td} only; >= 50x slower){p_end}
{synopt:{opt history(type)}}lag/instrument history scope under {cmd:if}/{cmd:in}: {cmd:panel} (default; the full panel is the history, consistent with how lagged regressors are materialized) or {cmd:sample} (hard boundary; the auto L.y is nulled where its source is out of sample, and user-typed ts-operator terms are REJECTED -- pre-generate the lags as plain variables or use {cmd:panel}){p_end}
{synopt:{opt trim(#)}}trim rate for γ grid (xthenreg convention); default {cmd:0.10}{p_end}

{syntab:Inference (Grid Bootstrap, Gong-Seo 2026)}
{synopt:{opt nocenter}}UNCENTERED clustered moment covariance (xtabond2 convention, for diagnostic cross-checks); the default is CENTERED (Seo-Shin eq. 11 / xthenreg){p_end}
{synopt:{opt gridci(#)}}# grid points for CI construction; minimum 10, default {cmd:100}; values below 100 are intended for quick checks, not final threshold inference{p_end}
{synopt:{opt boot(#)}}bootstrap replications; default {cmd:299}{p_end}
{synopt:{opt rseed(#)}}set deterministic component-specific seeds for threshold, linearity, continuity, and coefficient bootstraps; reproducible for the same data, command, Stata/RNG family, and package version{p_end}
{synopt:{opt noboot}}skip grid bootstrap (point estimate only){p_end}
{synopt:{opt vce(type)}}two-step covariance: {cmd:robust} (default; cluster-robust sandwich WITHOUT the Windmeijer correction) or {cmd:windmeijer} (adds the Windmeijer 2005 finite-sample correction){p_end}
{synopt:{opt coefboot(type)}}coefficient bootstrap replay: {cmd:twostep} (default; unavailable with {cmd:td}), {cmd:onestep}, or {cmd:none}{p_end}
{synopt:{opt coefcitype(type)}}coefficient-bootstrap interval: {cmd:symmetric} (default) or {cmd:percentile}{p_end}
{synopt:{opt notest}}skip the linearity and continuity test bootstraps (independent of the CI); for coverage-only runs needing only {cmd:e(gamma_lo)}/{cmd:e(gamma_hi)}{p_end}
{synopt:{opt nowarn}}suppress nonfatal advisory warnings/notes (boundary/disconnected sets, refinement and method caveats, small-N/instrument advisories); failure to deliver a requested coefficient CI is still reported{p_end}

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


{title:Changes in version 0.9.24 (16jul2026)}

{pstd}
Raised the default threshold-CI inversion grid from {cmd:gridci(25)} to
{cmd:gridci(100)}. Seeded Monte Carlo diagnostics with {cmd:boot(299)}
and {cmd:grid(100)} found materially better finite-sample threshold-set
coverage at {cmd:gridci(100)}, while point estimates were unchanged.
The command now prints a non-fatal note for {cmd:gridci()} values below
100 unless {cmd:nowarn} is specified.
{p_end}

{title:Changes in version 0.9.23 (13jul2026)}

{pstd}
Extended fail-closed numerical audit. Symmetric covariance, weight, and GMM
normal matrices must now be positive definite, not merely invertible and
well-conditioned. A failed cluster-robust sandwich can no longer fall back to
a model-based variance under the {cmd:vce(robust)} label. Refinement counts
valid coarse anchors separately from the appended refined optimum, and
{cmd:e(grid_admitted)} now requires a complete fixed-W1 solve.

{pstd}
Coefficient-bootstrap intervals are withheld if deviations or final bounds
overflow. Continuity comparisons use a jointly finite kink/jump set on the
sample and in every bootstrap draw. {cmd:boottype(unit)} compatibility gates
apply only when bootstrap inference runs, so {cmd:noboot} remains a pure
point-estimation path. An explicitly supplied {cmd:levmaxlag()} is rejected
outside {cmd:method(system)} instead of being silently ignored.

{title:Changes in version 0.9.22 (13jul2026)}

{pstd}
Fail-closed inference audit. Wild threshold-CI and linearity bootstrap draws
must now contain at least one finite unrestricted threshold-model objective;
the restricted objective alone can no longer manufacture a valid zero
distance after every alternative failed. Flat profiles remain admissible in
these tests because the threshold is a nuisance parameter under their nulls.
Cluster-sandwich and AR variance-component overflow now follow their
documented failure contracts, and refinement admits coarse anchors only after
a complete fixed-weight solve. {cmd:boottype(unit)} metadata now states the
implemented weighting precisely: fixed sample W1 and per-draw recentered
Omega/W2*.

{title:Changes in version 0.9.21 (12jul2026)}

{pstd}
Bootstrap replay hardening. Every coefficient-bootstrap and unit-bootstrap
draw now uses the same relative tie rule, smaller-gamma tie break, minimum
two-point search, and non-flat-profile identification gate as the reported
estimator. A unit draw can no longer be counted valid from the restricted
objective alone when its unrestricted stage-2 grid has no valid solution.
Bootstrap inference fails fast for {cmd:td} with {cmd:boottype(unit)} and
for {cmd:td} with {cmd:coefboot(twostep)}, because those paths would require
recomputing the time-effects FWL projection inside every draw. Use
{cmd:boottype(wild)} and {cmd:coefboot(onestep|none)} with {cmd:td};
{cmd:noboot} point estimation is unaffected. Nonfinite solver results from
overflow are rejected and counted as numerical failures rather than admitted
as valid profile points or bootstrap draws.

{title:Changes in version 0.9.20 (12jul2026)}

{pstd}
Numerical decisions are now invariant to ordinary changes of measurement
units. GMM objective ties, flat-profile checks, and continuity nesting use
purely relative tolerances. Symmetric normal, instrument, and moment matrices
are rank-checked after diagonal equilibration and, when needed, solved on that
balanced scale before being mapped back to the original coefficient units.
This also covers dynamic models, where rescaling the outcome rescales both
L.y design columns and lag-y instruments. In grid-CI inversion, status 2 is
reserved for an exact structural zero; every positive D statistic receives a
bootstrap critical value regardless of its absolute units. Restricted
objectives are explicitly included in the unit-CI and linearity comparison
sets so their distances are nonnegative by construction.

{title:Changes in version 0.9.19 (11jul2026)}

{pstd}
Second independent audit release. {cmd:predict} now recomputes the 53-bit
checksum from both actual Mata row caches and fails closed if either was
changed. Hansen and AR p-values use direct survival-tail evaluations,
avoiding cancellation to a false exact zero in extreme tails. The omitted
{cmd:maxlag()} upper bound is now truly open rather than silently capped at
9,999, with a pre-allocation IV-size gate preventing out-of-memory failures.
Equivalent pure lag spellings such as FL2.y can no longer duplicate the
automatic L.y regressor. Centering, history, predetermined timing, FOD time
effects, stored-result, coefficient-count, AR-predict, and bootstrap guidance
in this help file were synchronized with the implemented command.

{title:Changes in version 0.9.18 (11jul2026)}

{pstd}
Audit release. Fixed serial-collision corruption in cached {cmd:predict},
including fail-safe temporary output cleanup; continuity comparisons now use
the jointly feasible nested grid; static zero-RHS models with external IVs now
receive the linearity test; and seeded inference objects use component-specific
seeds. Local refinement now covers support beyond an edge anchor and counts
distinct support values. AR p-values require at least five pair-contributing
panel clusters. Sparse-calendar lookup and transformed-IV allocation are
memory-bounded/interval-compact without changing admitted moment columns.

{pstd}
New diagnostics include {cmd:e(p_cache_sig)}, {cmd:e(p_cache_token)},
{cmd:e(continuity_common_grid)}, {cmd:e(ar1_N_clust)}/{cmd:e(ar2_N_clust)},
and the requested/component seed metadata documented below.

{title:Changes in version 0.7.10 (02jul2026)}

{pstd}
Audit release. The threshold variable is now kept immutable when it also
appears as a regressor under {cmd:td}; trim bounds and regime-size guards use
the effective GMM stack; {cmd:e(sample)} marks contributing raw panel-time
rows; static exogenous models no longer inherit the dynamic t-2 requirement;
and non-unit {cmd:xtset} deltas are rejected explicitly.

{pstd}
Inference now reports the sandwich variance associated with the actual fixed
second-step GMM weight. Hansen J uses that same minimized criterion, and the
full AR correction receives the weight actually paired with {cmd:e(b)}.
The continuity bootstrap DGP is selected with the same one-step restricted
objective used by its sample and bootstrap statistics.

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
correction. That release still allowed a simplified b0/sqrt(T1) fallback;
current versions deliberately leave the statistic/p-value missing when the
full variance is unavailable or nonpositive.
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
construction across all methods and any panel pattern, guarded by the run
serial, exact per-fit token, cache checksum, and source-data signature. See
{help xtdpthresh##postest:Postestimation}.

{pstd}
{bf:New e() scalars and option.} {cmd:e(ar*_b0)}, {cmd:e(ar*_T1)},
{cmd:e(ar*_TT)} expose the AR m-statistic decomposition; {cmd:e(ar*_np)}
the lag-pair count (a negative sign flags unavailable full variance, not a
fallback statistic). New
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
{cmd:*} Two-step weight: {cmd:xtdpthresh} uses the CENTERED clustered
moment covariance of Seo-Shin (2016, eq. 11) and {cmd:xthenreg} by
default. {cmd:nocenter} switches to the uncentered Arellano-Bond /
{cmd:xtabond2} convention for diagnostic cross-checks. Both are
consistent under correct specification and differ by an O(1/n) term.

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
{cmd:*} Windmeijer caveat: by default the reported two-step {cmd:e(V)} is
the UNCORRECTED asymptotic two-step cluster-robust covariance — the
sandwich of the FIXED-weight estimator, treating the second-step weight as
known. Two-step SEs are therefore downward-biased in small n and will be
SMALLER than {cmd:xtabond2}'s Windmeijer-corrected {cmd:twostep robust}
SEs. v0.7.13 adds {cmd:vce(windmeijer)} to apply the Windmeijer (2005)
finite-sample correction (computed once at the final estimate; no runtime
cost); the default remains {cmd:vce(robust)} (the uncorrected
cluster-robust sandwich) for continuity.
{cmd:e(vce_requested)} records the request, {cmd:e(vce)} records the
covariance actually delivered, and {cmd:e(vce_applied)}=1 when the
correction was actually applied (two-step path).

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
{cmd:*} Added: {cmd:gridci()}, {cmd:boot()}, {cmd:noboot}
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

{pmore}
Note on the threshold variable as a regressor: placing the {cmd:qx()} variable
in {it:indepvars}, {opt endogenous()}, or {opt predetermined()} adds it as a
REGRESSOR — a coefficient on q is estimated — handled with that instrument
status. This is distinct from q's threshold role: q always enters the regime
split 1(q>γ) regardless. Thus {cmd:qx(cn) endogenous(cn)} means "cn is the
threshold variable AND an endogenous regressor," NOT "the threshold location
itself is treated as endogenous." Instrumenting q in its threshold role is
handled through the moment structure / {opt iv()}, not through {opt endogenous()}.

{phang}
{opt predetermined(varlist)} specifies regressors that may respond to
past shocks but are orthogonal to the current and future idiosyncratic
errors: in particular, E[x_{it} epsilon_{it}] = 0, while x_{it} may
correlate with epsilon_{i,t-1}. Predetermined regressors are instrumented
with lagged levels {x_{i,t-1}, x_{i,t-2}, ...} in the transformed
equation -- one more recent lag than {opt endogenous()} because
x_{i,t-1} is orthogonal to both terms in Delta epsilon_{it}. This is the
standard Arellano-Bond / Bond (2002) classification: use
{opt endogenous()} for variables jointly determined with y_{it}, and
{opt predetermined()} for lagged-feedback variables fixed before the
time-t shock. {it:predetermined()} variables must NOT appear in
{it:indepvars}, {opt exogenous()}, or {opt endogenous()}.

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
{opt exogenous()}): its transformed value — Δx_t under {cmd:method(fd)}
and its forward orthogonal deviation under {cmd:method(fod|system)} — so
exogenous variables instrument themselves under E[x · ε]=0;

{phang2}
(iv) for each variable in {opt endogenous()}: its own lags x_{t-2},
x_{t-3}, ... as Arellano-Bond moment conditions (lag 1 is reserved for
{opt predetermined()} variables).

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
satisfying E[z · ε] = 0 in the transformed block. In the level block the
stronger condition is E[z_it(η_i+ε_it)] = 0, so z must also be orthogonal to
the unit effect; otherwise use {cmd:method(fd|fod)} rather than system.
The {cmd:collapse} sub-option (v0.7.0 semantics) collapses ONLY the user-IV
block — one shared column per IV across all time blocks. Use the top-level
{cmd:collapse} option to collapse everything. The {cmd:maxlag()} sub-option
that existed in v0.6.x is removed in v0.7.5 (it never affected user IVs);
use the top-level {cmd:maxlag()} for GMM-style instrument lag control.

{phang}
{opt kink} requests the continuity-restricted (kink) model of Seo-Shin
(2016). Under this restriction, the model is continuous at γ:
δ_2 = 0_{p-1} and δ_1 + δ_3·γ = 0. The threshold variable's slope changes
at the threshold, but no jump occurs. Let K denote the number of base regressors after the
automatic L.depvar is added (unless {cmd:static}). The kink model has K+1
slope coefficients versus 2K+1 for the unrestricted jump model;
{cmd:method(system)} adds one level-equation constant to either.

{pmore}
The kink term is built from {cmd:qx()} as (q−γ)·1(q>γ). For a proper
two-sided kink — a baseline slope on q below γ plus a slope change above —
the threshold variable must ALSO appear as a regressor (in {it:indepvars},
{opt exogenous()}, {opt endogenous()}, or {opt predetermined()}). If it does
not, the level term has no baseline q slope and the model reduces to a
one-sided hinge (flat in q below γ); {cmd:xtdpthresh} prints a note in that
case (suppress with {opt nowarn}).

{phang}
{opt static} specifies a static model. The default is dynamic, which
automatically includes L.{it:depvar} as a regressor. With {cmd:static},
L.{it:depvar} is not auto-added; users must include any lag explicitly
in {it:indepvars}.
A zero-RHS static model is also allowed when {cmd:iv()} supplies an external
moment source; otherwise at least one regressor is required.

{pmore}
Sample scope: {cmd:history(panel)} is the default, so {cmd:if}/{cmd:in}
restrict the equation sample while the full panel remains available as
lag/instrument history. {cmd:history(sample)} instead makes
{cmd:if}/{cmd:in} a hard history boundary; the automatic L.y is nulled
when its source lies outside that boundary, and user-entered time-series
operators are rejected because they were materialized on the full panel.

{phang}
{opt td} controls for common time effects the FWL-CORRECT way (v0.7.13):
common-across-regime time dummies are partialled out of the final
transformed system — the transformed dependent variable, every column of
the design W(γ) = [X, 1(q>γ), X·1(q>γ)] (including the regime intercept
and the threshold interactions), and every instrument column are
cross-sectionally demeaned within each time cell, at every γ. This is
algebraically identical to including the dummies in both the regressor and
instrument sets: M_t[x·1(q>γ)], not M_t(x)·1(q>γ). Exact under
{cmd:method(fd)} (Δλ_t is common at each t by construction); exact under
{cmd:method(fod)} on ANY panel: the time dummies receive each unit's own
FOD operator and are partialled out by projection (v0.8.x), so no
balanced-panel restriction applies. Not available with {cmd:method(system)} (the level
constant would be collinear with the dummies). The threshold variable
{it:q} is untouched, so γ retains its original scale.

{pmore}
v0.8.0: the legacy {cmd:tdpurge} option (pre-demeaning of the input
variables before regime construction) has been REMOVED — it implemented
exactly the construction that is not equivalent to time dummies, and no
published results depend on it. {cmd:td} (FWL-correct) is the only
time-effects treatment; {cmd:e(td_mode)} is {cmd:fwl} when used. The
implemented projection is exact under {cmd:method(fd)} and under
{cmd:method(fod)} on balanced or unbalanced panels.

{pmore}
Bootstrap restriction: {cmd:td} is compatible with the default wild
threshold/test bootstrap and with {cmd:coefboot(onestep|none)}. It is not
available with {cmd:boottype(unit)} or {cmd:coefboot(twostep)}, because
those resampling paths require a draw-specific FWL projection that is not
currently rebuilt. {cmd:noboot} point estimation remains available.

{phang}
{opt collapse} collapses block-diagonal instruments across time periods
(Roodman 2009). By default, each moment (lag of y, Δx, endog lag, user
inst) gets a separate column per time block, causing the instrument
count to grow quadratically with T. With {cmd:collapse}, instruments
are stacked into a single shared column per lag depth, reducing the
total count by a factor of (T−2). Use this for long panels (T ≥ 10) to
mitigate instrument proliferation and make the Hansen J diagnostic less fragile.
Downside: weaker identification at each γ due to fewer moments.

{phang}
{opt maxlag(# [#])} restricts which lags are used as instruments,
analogous to xtabond2's {cmd:lag()} suboption.

{pmore}
{cmd:maxlag(L)} caps instrument lag depth at L. Predetermined variables use
lags 1 through L; endogenous variables and the auto-added L.y use lags 2
through L.

{pmore}
{cmd:maxlag(a b)} uses lags a through b inclusive. For example,
{cmd:maxlag(2 4)} uses lags 2, 3, 4. Useful when short lags are
"too recent" to be valid IVs (possibly still correlated with ε).

{pmore}
Combine with {cmd:collapse} for aggressive instrument reduction:
{cmd:maxlag(2 4) collapse} yields few moments and reliable Hansen J
at the cost of identification strength. Monitor {cmd:e(N_iv)} to
ensure the model remains identified (N_iv ≥ # regressors).

{pmore}
Resource safety: before allocating instruments, the command rejects a
nominal design above 5,000 IV columns or 50 million Z cells (before
exact-zero columns are pruned). This prevents an out-of-memory crash on
long or sparse calendars. Tighten {cmd:maxlag()}, add {cmd:collapse},
and under {cmd:method(system)} tighten {cmd:levmaxlag()}.

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
Works on balanced or unbalanced panels; equations without consecutive
observations are dropped. Matches {cmd:xthenreg} on comparable balanced designs.

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
The current implementation requires the active {cmd:xtset} time delta to be
1. Re-index coarser time values to consecutive integers before estimation;
other deltas return {cmd:r(459)} rather than silently constructing wrong lags.

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
{opt grid(#)} sets the number of grid points for the γ search. Default 100.
The former default 30 could select the wrong criterion basin; use an even
denser grid or a convergence check for final estimation when feasible.

{phang}
{opt gridtype(uniform|quantile)} sets how grid points are placed within the
trim range. {cmd:uniform} (default) spaces them equally in the VALUE of
{it:q_var} (the xthenreg-comparable convention). {cmd:quantile} places them
on empirical quantiles of {it:q_var} over the effective sample — roughly
equal observation counts between consecutive points, matching the layout
used in the Gong-Seo application — which concentrates resolution where the
data are dense and avoids wasted points in sparse regions; duplicate
quantiles from ties are collapsed, so the effective grid can hold fewer
points than requested. Applies to both the estimation grid and the CI grid;
the CI grid additionally contains the reported γ̂ and, for the wild
inversion, the one-step argmin that supplies its zero-distance point.

{phang}
{opt trim(#)} sets the trimming rate for the γ grid, using xthenreg's
convention: {cmd:trim(#)} trims {it:#}/2 from each tail of {it:q_var}.
Examples: {cmd:trim(0.10)} → grid spans [p5, p95]; {cmd:trim(0.20)} →
grid spans [p10, p90]; {cmd:trim(0.40)} → grid spans [p20, p80]. Must
be in [0.01, 0.45]. Default 0.10. Note: this differs from {cmd:xthreg}
/{cmd:xthreg2} which interpret the trim argument as a per-tail fraction.

{dlgtab:Inference}

{marker citype}{...}
{phang}
Threshold CI construction (v0.8.0 note: the former {cmd:citype()} option
was removed — it duplicated {opt noboot} exactly). By default the command
builds a grid bootstrap CI via test inversion within the framework of
Gong-Seo (2026, Section 4.1); {opt noboot} skips it and reports the point
estimate and coefficient SEs only.

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
scheme's empirical validity. {cmd:boottype(unit)} provides an experimental
unit-multiplicity, recentered, two-stage alternative for the FD jump model.
It holds the sample first-stage weight W1 fixed, then rebuilds the recentered
moment covariance and second-stage weight W2* in every draw; it is not
certified as the exact Algorithm 1 implementation.
It is not available with {cmd:td}, whose FWL projection would have to be
rebuilt under each draw's unit multiplicities.

{phang}
{opt gridci(#)} sets grid points for CI construction. Finer grid gives
more precise CI but slower runtime. Default 100. Values below 100 are intended for smoke tests and exploratory runs, not final threshold inference.

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
{opt boot(#)} sets bootstrap replications. The enforced minimum 10 is for
debugging only. The command prints a Monte Carlo advisory below 999:
99-199 draws are exploratory, 299-499 are suitable for preliminary
analysis, and 999 or more are recommended for final inference. A larger
B reduces simulation error but does not certify the bootstrap design.
Default 299.

{phang}
{opt rseed(#)} accepts an integer in [0, 2147483647]. v0.9.18 assigns
deterministic component-specific seeds to the threshold CI, linearity test,
continuity test, and coefficient bootstrap. Thus changing {cmd:gridci()},
{cmd:boottype()}, or {cmd:notest} no longer shifts the random draws of an
unrelated inference object. Bit-for-bit replication additionally requires
the same data/order, command, Stata/package version, and RNG family; these
are recorded in {cmd:e(rseed)}, {cmd:e(rng)}, and {cmd:e(seed_*)}.

{phang}
{opt noboot} skips the grid bootstrap CI (and the linearity/continuity
test bootstraps) entirely: point estimate and conditional slope SEs only.

{phang}
{opt notest} skips the linearity and continuity test bootstraps only,
while still constructing the threshold CI. The two test bootstraps are
independent of the CI inversion, so this is useful for coverage or
simulation runs that need only {cmd:e(gamma_lo)} and {cmd:e(gamma_hi)}:
{cmd:e(pval_lin)} and {cmd:e(pval_cont)} are left missing. CI bounds are
bit-for-bit identical to a full run with the same {cmd:rseed()}.

{phang}
{opt vce(robust|windmeijer)} selects the two-step covariance for the
slope parameters. {cmd:vce(robust)} (default) reports the asymptotic
two-step CLUSTER-ROBUST sandwich of the fixed-weight estimator without
the Windmeijer small-sample correction (renamed from the pre-release
name {cmd:uncorrected}, which wrongly suggested a nonrobust VCE). {cmd:vce(windmeijer)} applies the Windmeijer
(2005) finite-sample correction — accounting for the estimation error in
the second-step weight — matching the convention of {cmd:xtabond2}'s
{cmd:twostep robust}. The correction is computed once at the final estimate
and has no effect on the threshold grid search or threshold/test bootstraps
(all one-step). The coefficient bootstrap is separate:
{cmd:coefboot(twostep)} replays two-step point estimates draw by draw, but
its empirical interval does not use an analytic VCE. On the rare one-step
fallback path the Windmeijer correction is undefined and the paired robust
sandwich is reported with {cmd:e(vce_applied)}=0.
{cmd:e(vcetype)} is always "Conditional on estimated threshold": ALL
analytic slope SEs treat γ̂ as fixed and are not continuity-robust
(threshold inference runs through the grid bootstrap CI). The Windmeijer
correction is likewise conditional on the selected threshold — it does not
add γ-search variability. A full-Jacobian joint VCE (kernel G_γ, Seo-Shin)
and the Gong-Seo coefficient bootstrap are planned.

{phang}
{opt nocenter} switches the clustered moment covariance (second-step
weight and sandwich meat) to the UNCENTERED Arellano-Bond / {cmd:xtabond2}
convention, for cross-checking Hansen/AR against {cmd:xtabond2}. v0.8.1:
the DEFAULT is the CENTERED form of Seo-Shin (2016, eq. 11) and
{cmd:xthenreg} — the convention of the estimator this command implements
(the two differ by an O(1/n) term; centering mainly improves the power of
the overidentification test under misspecification).

{phang}
{opt coefboot(twostep|onestep|none)} — how each coefficient-bootstrap draw
re-estimates the model. Default {cmd:twostep} replays the REPORTED
estimator (stage-1 argmin, Omega*, stage-2 grid pass with W2* fixed);
{cmd:onestep} is the fast fixed-weight replay; {cmd:none} skips the
coefficient bootstrap. This scheme is a threshold-search-aware cluster
wild residual bootstrap -- it is NOT the Gong-Seo coefficient bootstrap
(which resamples units' regressors/instruments/residuals jointly,
recenters moments, rebuilds weights, and uses a shrinkage null estimate);
{cmd:coefboot(gs)} is reserved and currently rejected.

{pmore}
With {cmd:td}, specify {cmd:coefboot(onestep)} or {cmd:coefboot(none)}.
The two-step coefficient replay is rejected because Omega* requires the
time-effects FWL projection to be recomputed separately in every draw.

{pmore}
The coefficient bootstrap is fixed-B: exactly the requested draws are
attempted once. Failed numerical draws are discarded, never replaced by a
different estimator and never redrawn. {cmd:e(b_bootci)} is posted only when
at least 90% of the requested draws and at least 10 draws succeed. A draw
succeeds only if each required search stage has at least two valid grid
points and a non-flat profile, using the same relative objective tie rule
and smaller-gamma tie break as the reported estimator.

{phang}
{opt coefcitype(symmetric|percentile)} — form of the coefficient bootstrap
intervals in {cmd:e(b_bootci)}. Default {cmd:symmetric}
(θ̂ ± c*, c* the (1−α) quantile of |θ*−θ̂|; Gong-Seo report that raw
percentile intervals can under-cover). {cmd:percentile} gives the raw
form.

{phang}
{opt nowarn} suppresses nonfatal advisory warnings and notes, including the
CI-boundary pinning warning, disconnected-set/refinement notes, and method or
small-sample/instrument advisories. It never suppresses failure to deliver a
requested coefficient interval. By default,
{cmd:xtdpthresh} prints a warning when either CI bound equals an edge of
the CI grid's ADMITTED span (within 10^-4 of that span; stored in
{cmd:e(gamma_ci_grid_lo)}/{cmd:e(gamma_ci_grid_hi)}). The confidence set
is inverted on the CI grid, so its own admitted range -- not the trim
bounds and not the estimation grid -- is the relevant frame. Boundary
pinning signals
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
{cmd:      method(fd) noboot}{p_end}

{pstd}
Full grid bootstrap with fine settings:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow, qx(debt)}{break}
{cmd:      method(fd) grid(100) gridci(100) boot(499) trim(0.10)}{p_end}

{pstd}
System GMM with dense instruments:

{phang2}{cmd:. xtdpthresh y x1, qx(q)}{break}
{cmd:      endogenous(x2) method(system) grid(40)}{p_end}

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
{synopt:Required}one statistic must be specified explicitly (v0.9.6; there is no silent default -- these are cached estimation-row series, not current-data predictions){p_end}
{synopt:{opt r:esiduals}}residual of the ESTIMATED equation: FD residual under {cmd:method(fd)}, FOD residual under {cmd:method(fod)}, FD-restack residual under {cmd:method(system)} (level-equation residuals are not yet exposed){p_end}
{synopt:{cmd:arresiduals}}the FD residual series the AR(1)/AR(2) tests consume (xtabond2 convention, always FD-form). For {cmd:method(fd)} this equals {cmd:residuals}; for {cmd:method(fod)} it is the FD restack and differs from the FOD estimation residual in variance and pattern; for {cmd:method(system)} it equals {cmd:residuals}{p_end}
{synopt:{cmd:xb}}fit of whichever equation {cmd:residuals} corresponds to ({cmd:residuals + xb} = transformed depvar row-by-row). This is the CACHED transformed-equation fit on estimation rows only -- not an out-of-sample or current-data linear prediction{p_end}
{synopt:{opt reg:ime}}regime indicator 1{c -(}q_it > γ̂{c )-} on raw rows within {it:if}/{it:in} (not restricted to e(sample)){p_end}

{pstd}
v0.7.13: {cmd:predict e, r} returns {cmd:residuals} (the standard Stata
idiom); {cmd:regime} must be abbreviated no shorter than {cmd:reg}. In
earlier versions the single letter {cmd:r} silently matched {cmd:regime}.

{pstd}
Use {cmd:arresiduals}, not {cmd:residuals}, to reproduce the reported
AR(1)/AR(2) statistics under {cmd:method(fod)}: the FOD estimation
residual has a different variance and a mechanical first-order
autocorrelation, so an AR test on it would not match the reported value.
Under {cmd:method(fd)} and {cmd:method(system)} the two coincide.

{pstd}
Both {cmd:residuals} and {cmd:arresiduals} are merged into the new
variable by ({it:panelvar}, {it:timevar}) key from rows persisted in Mata
during estimation, keyed by run serial plus an exact per-fit token and cache
checksum (the 20 most recent runs are kept, so
{cmd:estimates store}/{cmd:restore} works within a session) — identical
by construction to the estimation-time series, for every method and any
panel pattern. No transformation, trim, t-2 instrument-history, or
zero-instrument filter is re-derived in {cmd:predict}. Rows outside the
estimator's row set return missing.

{pstd}
{bf:Staleness and data integrity.} {cmd:predict} requires intact Mata
state and UNCHANGED source data. The source columns (panel/time keys,
depvar, qx(), and the base variables of all regressors and instruments)
are signed at estimation; {cmd:predict} refuses with rc 459 when the
signature no longer matches -- cached residuals/fits are estimation-time
values, and serving them over edited data (or a different dataset with
coincident keys) would be silently wrong. Other error paths: rc 498 after
{cmd:mata: mata clear}, {cmd:discard}, a Stata restart, a serial/token
mismatch, or when the run was evicted (more than 20 newer runs); rc 301 for
cached statistics if e() predates the v0.9.18 exact cache guard. A failed
cache lookup does not leave the requested new variable behind.

{pstd}
Example — extract residuals after {cmd:method(fd)}:

{phang2}{cmd:. xtdpthresh invest tobin_q cashflow debt, qx(debt) method(fd) maxlag(2 4) noboot}{p_end}
{phang2}{cmd:. predict double ehat, residuals}{p_end}
{phang2}{cmd:. predict byte regime_hat, regime}{p_end}

{pstd}
{cmd:arresiduals} enables external verification of the AR(k) statistic
against {cmd:abar} or any reimplementation. With the AR-test residuals
available the user can reproduce the numerator and full denominator by
computing b0 = Σ_i Σ_t ê_{i,t}·ê_{i,t-k} and T1 = Σ_i (Σ_t
ê_{i,t}·ê_{i,t-k})² externally and comparing against {cmd:e(ar*_b0)} and
{cmd:e(ar*_T1)}; the full denominator {cmd:e(ar*_T1)} + {cmd:e(ar*_TT)}
accounts for the T2+T3 parameter-uncertainty correction (see B1 status
in {help xtdpthresh##changelog:Changes}).


{title:Stored results}

{pstd}
{cmd:e(sample)} marks the union of raw ({it:panelvar},{it:timevar}) rows that
contributed to at least one estimation equation. v0.7.13: {cmd:e(N)} now
counts exactly those raw rows, so {cmd:e(N)} = {cmd:count if e(sample)}
always — including under {cmd:method(system)}, where the stacked design has
more equation rows than raw observations; the stacked row count is stored
separately in {cmd:e(N_stack)} (= N_trans + N_level).

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}raw panel-time observations in the estimation sample (= count if e(sample)){p_end}
{synopt:{cmd:e(N_stack)}}stacked GMM equation rows (= N_trans + N_level){p_end}
{synopt:{cmd:e(N_raw)}}complete-case (equation-eligible) rows. v0.8.1: history-only rows — in-scope rows failing complete-case — are additionally RETAINED as instrument sources (value-guarded), matching xthenreg's full-panel instrument construction; they never form equations and are excluded from e(N_raw), e(N), and e(sample){p_end}
{synopt:{cmd:e(N_trans)}}transformed rows (FD or FOD equations){p_end}
{synopt:{cmd:e(N_level)}}level equation rows (nonzero only for {cmd:method(system)}){p_end}
{synopt:{cmd:e(N_iv)}}number of instruments (columns of Z after dropping zero cols){p_end}
{synopt:{cmd:e(N_units)}}number of panel units used{p_end}
{synopt:{cmd:e(N_units_trans)}, {cmd:e(N_units_level)}, {cmd:e(N_units_both)}}units contributing transformed rows, level rows, and both (level counts nonzero only for {cmd:method(system)}); thin or one-sided participation triggers symmetric warnings, and fewer than 5 clusters in either block (or zero overlap) is a hard error{p_end}
{synopt:{cmd:e(diffhansen_level)}, {cmd:e(diffhansen_level_df)}, {cmd:e(diffhansen_level_p)}}Difference-in-Hansen (C statistic) for the ADDITIONAL level moments under {cmd:method(system)}: J_system - J_fod, with the FOD side FULLY re-estimated including its own threshold search; df = L_sys - L_fod - 1; missing on one-step paths. A negative difference is NOT clamped: p is missing and {cmd:e(diffhansen_negative)}=1 flags the diagnostic as unreliable{p_end}
{synopt:{cmd:e(hansen_fod)}, {cmd:e(hansen_fod_df)}, {cmd:e(hansen_fod_p)}, {cmd:e(gamma_fod)}}the reduced (FOD-only) side of the C statistic, for inspection{p_end}
{synopt:{cmd:e(gridboot_min_draws)}}smallest per-gamma-point count of valid bootstrap replications behind the CI inversion; a point needs max(10, ceil(0.9B)) valid draws, otherwise status 5 is UNRESOLVED rather than rejected{p_end}
{synopt:{cmd:e(ci_segments)}}matrix of accepted [lower, upper] gamma segments -- the actual confidence SET; the reported [e(gamma_lo), e(gamma_hi)] hull is only a summary and can cover rejected gamma when e(ci_nseg) > 1{p_end}
{synopt:{cmd:e(ci_grid)}}full inversion table: gamma, D statistic, critical value, accepted flag, valid draws, and a status code (1 valid result; 2 mechanical accept, D=0 exactly; 3 structurally inadmissible; 4 sample solve failed; 5 too few valid draws; 6 quantile failed). Every D>0 is bootstrapped regardless of its absolute measurement units. Statuses 4-6 are UNRESOLVED, not rejections{p_end}
{synopt:{cmd:e(ci_unresolved)}, {cmd:e(ci_incomplete)}}number of unresolved gamma points and a 0/1 flag. When 1, the inversion is INCOMPLETE and no formal confidence set is reported: {cmd:e(gamma_lo)}/{cmd:e(gamma_hi)}/{cmd:e(ci_empty)}/{cmd:e(ci_nseg)} are missing, and the acceptance runs over the evaluated points only are stored as {cmd:e(ci_segments_evaluated)} (explicitly not a formal set){p_end}
{synopt:{cmd:e(boot_threshold_requested)}, {cmd:e(boot_linearity_requested)}, {cmd:e(boot_linearity_valid)}, {cmd:e(boot_continuity_requested)}, {cmd:e(boot_continuity_valid)}}requested-draw and valid-draw accounting for each inference object; test p-values require at least 90% of the request and at least 10 valid draws{p_end}
{synopt:{cmd:e(continuity_common_grid)}}number of gamma points jointly one-step feasible for both kink and jump designs on the same row sample; the continuity test is unavailable when fewer than 2{p_end}
{synopt:{cmd:e(hansen)}}Hansen J over-identification statistic -- a DIAGNOSTIC conditional on the grid-selected γ̂ (possibly irregular under the null), not a fully standard specification test{p_end}
{synopt:{cmd:e(hansen_df)}}Hansen J degrees of freedom (N_iv − k_W − 1; γ counts as an estimated parameter, v0.8.0). Under continuity treat J as a diagnostic{p_end}
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
{synopt:{cmd:e(ar1_np)}}AR(1) lag-pair count; positive when the full AB variance was delivered, negative when its parameter-variance pieces failed (the statistic/p-value are then missing; no simplified fallback){p_end}
{synopt:{cmd:e(ar2_np)}}AR(2) lag-pair count with the same sign convention; missing when basic pair/cluster support is insufficient{p_end}
{synopt:{cmd:e(ar1_N_clust)}, {cmd:e(ar2_N_clust)}}panel clusters contributing at least one AR lag pair; at least 5 are required for a reported N(0,1) p-value{p_end}
{synopt:{cmd:e(gamma)}}threshold point estimate γ̂{p_end}
{synopt:{cmd:e(gamma_lo)}}grid bootstrap CI lower bound (missing when the set is empty or the inversion is incomplete){p_end}
{synopt:{cmd:e(gamma_hi)}}grid bootstrap CI upper bound (missing when the set is empty or the inversion is incomplete){p_end}
{synopt:{cmd:e(ci_empty)}}1 if the bootstrap rejected every grid point (no CI), 0 otherwise{p_end}
{synopt:{cmd:e(ci_nseg)}}number of connected segments in the acceptance region (1 = standard CI; >1 = disconnected, hull reported){p_end}
{synopt:{cmd:e(pval_lin)}}linearity-test p-value from a profiled one-step GMM-distance statistic with wild bootstrap (not the Seo-Shin sup-Wald); add-one corrected{p_end}
{synopt:{cmd:e(pval_cont)}}continuity-test p-value from the nested profile GMM-distance on the common feasible grid; add-one corrected; missing under {cmd:kink} or when the comparison is unavailable{p_end}
{synopt:{cmd:e(obj)}}GMM objective at γ̂{p_end}
{synopt:{cmd:e(k_exog)}}# exogenous regressors{p_end}
{synopt:{cmd:e(k_endog)}}# endogenous regressors{p_end}
{synopt:{cmd:e(k_predet)}}# predetermined regressors{p_end}
{synopt:{cmd:e(k_inst)}}# user-supplied instruments{p_end}
{synopt:{cmd:e(flag_kink)}}1 if kink option specified{p_end}
{synopt:{cmd:e(flag_static)}}1 if static option specified{p_end}
{synopt:{cmd:e(flag_td)}}1 if td option specified{p_end}
{synopt:{cmd:e(balanced)}}1 if contributing units share the same panel-time union in the final effective stack{p_end}
{synopt:{cmd:e(panel_balanced)}}1 if the original xtset panel was strongly balanced before estimation-sample restrictions{p_end}
{synopt:{cmd:e(boundary_warn)}}grid-CI boundary-pin flag (0 none, 1 lower, 2 upper, 3 both){p_end}
{synopt:{cmd:e(q_lo)}}effective-sample lower trim bound (γ grid domain lower edge){p_end}
{synopt:{cmd:e(q_hi)}}effective-sample upper trim bound (γ grid domain upper edge){p_end}
{synopt:{cmd:e(p_serial)}, {cmd:e(p_cache_sig)}}serial and recomputed 53-bit checksum guarding the actual cached {cmd:predict} row matrices{p_end}
{synopt:{cmd:e(p_cache_token)}}exact Stata-generated per-fit token; prevents a reset Mata serial from aliasing restored results. The 20 most recent runs are kept; a clear/restart still requires re-estimation{p_end}
{synopt:{cmd:e(p_dsig)}, {cmd:e(p_dsig_vars)}}source-data signature and signed columns used to refuse stale cached fitted values/residuals{p_end}
{synopt:{cmd:e(level)}}confidence level of the reported intervals{p_end}
{synopt:{cmd:e(vce_applied)}}1 if the Windmeijer correction was applied to {cmd:e(V)}{p_end}
{synopt:{cmd:e(gamma_grid1_lo)}, {cmd:e(gamma_grid1_hi)}}span of the ADMITTED estimation grid (ok and one-step-solvable points, after minregime/ties/rank/conditioning pruning) — the stage-1 search space endpoints{p_end}
{synopt:{cmd:e(gamma_grid2_lo)}, {cmd:e(gamma_grid2_hi)}}span of the two-step search space (points solvable under the second-step weight; missing on one-step-only paths) — a two-step γ̂ is selected over this span, which can extend beyond the stage-1 span{p_end}
{synopt:{cmd:e(grid_requested)}, {cmd:e(grid_effective)}, {cmd:e(grid_admitted)}}estimation-grid bookkeeping: points requested, distinct after ties, and admitted (structurally ok AND one-step-solvable){p_end}
{synopt:{cmd:e(grid_structural)}}points passing the structural (sample-size/rank) admission only{p_end}
{synopt:{cmd:e(grid_twostep_admitted)}}points solvable under the second-step weight W2 (missing on one-step-only paths){p_end}
{synopt:{cmd:e(gridci_requested)}, {cmd:e(gridci_effective)}, {cmd:e(gridci_admitted)}}CI-grid bookkeeping: the gridci() request, distinct points actually inverted (including the appended γ̂), and those admitted{p_end}
{synopt:{cmd:e(gridci_sample_admitted)}, {cmd:e(gridci_evaluated)}}CI points with a successful sample-side solve and points with a resolved bootstrap result; they differ when a point is unresolved{p_end}
{synopt:{cmd:e(gamma_ci_grid_lo)}, {cmd:e(gamma_ci_grid_hi)}}admitted span of the CI grid — the reference frame for the boundary-pin warning{p_end}
{synopt:{cmd:e(minregime_requested)}}the minregime() request (0 = default rule){p_end}
{synopt:{cmd:e(refine_requested)}, {cmd:e(refine_iterations)}, {cmd:e(refine_added)}}refine() bookkeeping: iterations requested, performed, and support points added to the grid{p_end}
{synopt:{cmd:e(refine_pool)}, {cmd:e(refine_remaining)}, {cmd:e(refine_exhausted)}}candidate-pool accounting (expand-only union of coarse basins visited by γ̂){p_end}
{synopt:{cmd:e(refine_hull_lo)}, {cmd:e(refine_hull_hi)}}convex hull of the pooled coverage (basins need not be contiguous){p_end}
{synopt:{cmd:e(refine_final_in_initial_basin)}, {cmd:e(refine_neigh_unevaluated)}, {cmd:e(refine_complete)}}completeness: whether γ̂ stayed in the first basin, how many support points around the final γ̂ remain unevaluated, and whether refinement is complete (pool consumed AND final neighbourhood fully evaluated){p_end}
{synopt:{cmd:e(minregime_default)}, {cmd:e(minregime_applied)}}the default trimming floor for this sample and the floor actually applied (the max of the two){p_end}
{synopt:{cmd:e(trim)}}the trim() rate in effect{p_end}
{synopt:{cmd:e(boot_coef_failed)}, {cmd:e(boot_coef_fail_rate)}}failed coefficient-bootstrap draws and their share of fixed-B attempts. Failed draws are discarded, never replaced by one-step estimates and never redrawn; the CI requires at least 90% of requested draws valid and at least 10{p_end}
{synopt:{cmd:e(boot_grid_stage1)}, {cmd:e(boot_grid_stage2)}}sizes of the coefficient-bootstrap replay search spaces (stage 1 = one-step-solvable list; stage 2 = all structurally-ok points, conditioning tested under each draw's W2){p_end}
{synopt:{cmd:e(boot_coef_requested)}, {cmd:e(boot_coef_attempted)}, {cmd:e(boot_coef_success)}, {cmd:e(boot_coef_valid)}}coefficient-bootstrap accounting: requested, attempted, successful, and whether a CI was produced (requires both at least 10 and at least 90% of the request){p_end}
{synopt:{cmd:e(boot_coef_B)}, {cmd:e(boot_coef_twostep)}, {cmd:e(boot_grid_skipped)}}legacy success count, successful two-step replay count, and gamma-grid points skipped by the coefficient-bootstrap fast path{p_end}
{synopt:{cmd:e(diffhansen_cluster_mismatch)}}1 when system and reduced-FOD fits use different panel-cluster universes; the difference-in-Hansen subtraction is then withheld{p_end}
{synopt:{cmd:e(rseed)}, {cmd:e(seed_threshold)}, {cmd:e(seed_linearity)}, {cmd:e(seed_continuity)}, {cmd:e(seed_coefficient)}}requested and component-specific seeds; missing for objects not run or when rseed() was omitted{p_end}
{synopt:{cmd:e(ci_bootstrap_certified)}, {cmd:e(gamma_regular_rank_certified)}}both currently 0: the available bootstrap is not certified as exact Algorithm 1 and regular joint threshold rank is not established by the numerical gates{p_end}
{synopt:{cmd:e(estimator_twostep)}}1 when the reported point estimate completed the two-step search, 0 on the one-step fallback{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdpthresh}{p_end}
{synopt:{cmd:e(cmdline)}}the command line as typed{p_end}
{synopt:{cmd:e(vce)}}two-step covariance actually delivered ({cmd:robust} or {cmd:windmeijer}){p_end}
{synopt:{cmd:e(vce_requested)}}the vce() request (differs from e(vce) only on the one-step fallback){p_end}
{synopt:{cmd:e(gridtype)}}{cmd:uniform} or {cmd:quantile}{p_end}
{synopt:{cmd:e(gridsample)}}{cmd:effective} or {cmd:observed}{p_end}
{synopt:{cmd:e(boottype)}}{cmd:wild} or {cmd:unit} (threshold-CI bootstrap scheme){p_end}
{synopt:{cmd:e(rng)}}Stata RNG family active for the seeded run{p_end}
{synopt:{cmd:e(threshold_bootstrap)}, {cmd:e(threshold_resampling)}, {cmd:e(threshold_recentering)}}scheme metadata for the threshold CI specifically; {cmd:e(coefficient_bootstrap)}, {cmd:e(linearity_bootstrap)}, {cmd:e(continuity_bootstrap)} describe the other bootstrap objects (always wild){p_end}
{synopt:{cmd:e(threshold_search)}, {cmd:e(continuity_kink_search)}}actual fixed/refined threshold-search status and the finite-grid status of the restricted kink search{p_end}
{synopt:{cmd:e(linearity_statistic)}, {cmd:e(continuity_test)}}implemented specification-statistic descriptions and availability{p_end}
{synopt:{cmd:e(coefboot_requested)}, {cmd:e(coefboot)}, {cmd:e(coefcitype)}}requested and applied coefficient-bootstrap replay, and interval construction{p_end}
{synopt:{cmd:e(threshold_bootstrap_conditioning)}, {cmd:e(coef_bootstrap_conditioning)}}finite-solve conditioning and failure-withdrawal conventions for delivered bootstrap inference{p_end}
{synopt:{cmd:e(hansen_reference)}, {cmd:e(ar_vcetype)}}interpretation metadata for Hansen and Arellano-Bond diagnostics{p_end}
{synopt:{cmd:e(history)}}{cmd:panel} or {cmd:sample} (lag/instrument history scope){p_end}
{synopt:{cmd:e(balanced_definition)}}definition used by {cmd:e(balanced)}{p_end}
{synopt:{cmd:e(vcetype)}}"Conditional on estimated threshold"{p_end}
{synopt:{cmd:e(td_mode)}}"fwl" when td was used{p_end}
{synopt:{cmd:e(cmdversion)}}command version string{p_end}
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
{bf:Kink (continuity-restricted) model} — K+1 coefficients (K+2 under {cmd:method(system)}):

{phang2}{cmd:Lag_y_b}       coefficient on L.{it:depvar} (if dynamic){p_end}
{phang2}{cmd:<var>_b}       coefficient on {it:var}{p_end}
{phang2}{cmd:kink_slope}    change in slope of threshold variable at γ (δ_3){p_end}
{phang2}{cmd:cons_lvl}      level-equation constant (LAST element; {cmd:method(system)} only){p_end}


{title:Specification tests (reported automatically)}

{pstd}
{cmd:xtdpthresh} reports three standard dynamic panel GMM specification
tests after every estimation:

{phang}
{bf:Hansen J over-identification test}: {it:H}_0 = moment conditions are
valid. Statistic {cmd:e(hansen)} = n·ḡ'Ω̂⁻¹ḡ at θ̂ ~ χ²(df), where
df = N_iv − #params. Reject → moment misspecification. {it:Caveat:}
instrument proliferation weakens the Hansen diagnostic and often produces
implausibly high p-values; treat it as unreliable (Roodman 2009). Apply
{cmd:collapse} or {cmd:maxlag()} and check whether the conclusion persists.

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
as e(ar*_b0), e(ar*_T1), e(ar*_TT), and the underlying FD-form residuals are
returned by {cmd:predict, arresiduals}; this enables external bit-for-bit
verification against {cmd:abar} or any reimplementation of the Arellano-Bond
formula (see {help xtdpthresh##postest:Postestimation}). No T1-only fallback
is substituted: if T2/T3 are unavailable, the full variance is nonpositive,
or fewer than five panel clusters contribute lag pairs, the statistic and
p-value are left missing. For
{cmd:method(fod|system)}, the AR(k) test residuals are restacked into
first-differences (matching the {cmd:xtabond2} convention); T2/T3 use the
estimation-equation residuals/instruments/regressors. Benchmark against
{cmd:xtabond2} on linear DPD specifications gives a model-effect comparison
rather than a clean formula comparison — for the latter, use
{cmd:predict, arresiduals} followed by an external full-AB implementation
on the same residual series.

{title:Hypothesis tests (bootstrap-based; skipped under noboot/notest)}

{pstd}
{cmd:xtdpthresh} reports three specification tests when grid bootstrap
inference is enabled (the default; disabled by {cmd:noboot}):

{phang}
{bf:Threshold CI} (Gong-Seo 2026 §4.1): 100(1-α)% confidence interval
for γ constructed by test inversion. For each γ_ℓ in a grid, the null
γ = γ_ℓ is tested via the GMM distance statistic D_n(γ_ℓ); γ_ℓ is
accepted if D_n(γ_ℓ) ≤ (1-α)-quantile of bootstrap distribution D*_n.
The reported interval is the hull of accepted γ_ℓ, with the full segment set
stored separately when the inversion is complete. The Gong-Seo framework
targets uniform validity across continuous/discontinuous cases; the available
wild and unit implementations here remain approximations and are explicitly
marked {cmd:e(ci_bootstrap_certified)}=0. Stored in {cmd:e(gamma_lo)} and
{cmd:e(gamma_hi)} only for a complete inversion.

{phang}
{bf:Linearity test}: tests H0: δ = 0 (no threshold effect). The implemented
statistic is the difference between the restricted linear-model one-step GMM
objective and the minimum unrestricted one-step profile objective, with a
unit-level Mammen wild bootstrap under H0. It is not the Seo-Shin sup-Wald.
Low p-value rejects linearity. Stored in {cmd:e(pval_lin)}.

{phang}
{bf:Continuity test} (Gong-Seo 2026, Section 4.3 and Theorem 7): tests H0: model is
continuous (kink) vs H1: discontinuous (jump). Test statistic
T_n = n·(Q̂_kink(θ̃) - Q̂_jump(θ̂)). Bootstrap p-value under kink DGP.
Low p-value rejects continuity → use the unrestricted (jump) model.
High p-value (> 0.10) supports the kink specification. Stored in
{cmd:e(pval_cont)}. Only computed when {cmd:kink} is NOT set (the test
compares unrestricted vs kink; it makes no sense under kink estimation).
Both models must solve at least two common gamma points on the same row
sample; otherwise the p-value is missing and
{cmd:e(continuity_common_grid)} reports the shortfall.


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
replication is a single matrix-vector product. The current defaults are
{cmd:grid(100) gridci(100) boot(299)}; runtime is data-, method-, and
instrument-count dependent (System GMM is slowest, FD fastest). For exploratory work
use {cmd:grid(15) gridci(10) boot(99)} or {cmd:noboot}; for published
results use the defaults.

{pstd}
{cmd:*} {bf:Linearity test}: the p-value from {cmd:e(pval_lin)} uses the
profile GMM-distance statistic described above with a wild bootstrap. It is
not numerically or algebraically the sup-Wald statistic used by
{cmd:xthenreg}; do not interpret the two p-values as the same test.

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
