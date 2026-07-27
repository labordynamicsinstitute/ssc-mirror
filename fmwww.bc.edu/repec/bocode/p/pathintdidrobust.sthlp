{smcl}
{* *! version 1.0.0  15jul2026}{...}
{viewerjumpto "Syntax" "pathintdidrobust##syntax"}{...}
{viewerjumpto "Description" "pathintdidrobust##description"}{...}
{viewerjumpto "Options" "pathintdidrobust##options"}{...}
{viewerjumpto "Stored results" "pathintdidrobust##results"}{...}
{viewerjumpto "Examples" "pathintdidrobust##examples"}{...}
{viewerjumpto "References" "pathintdidrobust##references"}{...}
{title:Title}

{phang}
{bf:pathintdidrobust} {hline 2} Robustness checks and specification tests for Path-Integrated Difference-in-Differences (PI-DiD)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pathintdidrobust} {it:depvar} {ifin} {cmd:,}
{cmd:panelvar(}{it:varname}{cmd:)}
{cmd:timevar(}{it:varname}{cmd:)}
{cmd:treatvar(}{it:varname}{cmd:)}
{cmd:t0(}{it:#}{cmd:)}
[{cmd:t1(}{it:#}{cmd:)} {cmd:level(}{it:#}{cmd:)} {cmd:maxanticip(}{it:#}{cmd:)} {cmd:notable}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt panelvar(varname)}}unit (id) identifier{p_end}
{synopt:{opt timevar(varname)}}calendar/period variable{p_end}
{synopt:{opt treatvar(varname)}}time-invariant 0/1 treatment-group indicator{p_end}
{synopt:{opt t0(#)}}baseline period (start of the post-treatment window){p_end}

{syntab:Optional}
{synopt:{opt t1(#)}}evaluation horizon (endline); default is the maximum
observed value of {it:timevar}{p_end}
{synopt:{opt level(#)}}confidence level for reported intervals; default
is {cmd:level(95)}{p_end}
{synopt:{opt maxanticip(#)}}maximum number of pre-treatment grid points by
which the reference baseline is shifted back when building the
anticipation-robustness sensitivity curve; default is {cmd:maxanticip(0)}
(check (C) skipped){p_end}
{synopt:{opt notable}}currently unused; reserved for future use{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:pathintdidrobust} is the companion diagnostic command to
{help pathintdid} and implements the three robustness checks and
specification tests described in section 5 of the companion paper
(Salavi 2026). All three diagnostics operate on the same estimand,
sigma = INTEGRAL_t0^t1 tauhat(t) dt, and the same cluster-robust,
individual-level standard errors as {cmd:pathintdid} itself, so results
from the two commands are directly comparable.

{pstd}
{bf:(A) Dynamic placebo test for pre-treatment parallel trends.} Using
whatever survey waves are recorded before {opt t0()}, {cmd:pathintdidrobust}
computes the pre-treatment cumulative envelope

{center:sigma_pre = INTEGRAL_{t_{-P}}^{t0} tauhat(t) dt}

{pstd}
together with its standard error (a "PCE" Z-test of H0: sigma_pre = 0),
and a joint Wald test of H0: tau_pre = 0 across all P pre-treatment
gaps, using the same group-specific covariance construction as the main
estimator. If no wave is recorded before {opt t0()}, this check reports
a note and is skipped -- it is not silently omitted.

{pstd}
{bf:(B) Sensitivity to grid density and quadrature scheme.} Because
sigma-hat is a trapezoidal-rule approximation to a continuous integral,
{cmd:pathintdidrobust} recomputes it on a coarsened grid that keeps only
every second post-treatment survey wave (K/2 intervals instead of K) and
also computes Simpson's 1/3 rule estimate on the original grid. Large
discrepancies between the trapezoidal and Simpson estimates suggest that
tau(t) has curvature not well captured by the path-smoothness assumption
of the companion paper, and that a finer survey grid would improve
estimation. This check requires an even number of equally spaced
post-treatment intervals between {opt t0()} and {opt t1()}; otherwise it
reports a note and is skipped.

{pstd}
{bf:(C) Anticipation-robust bounding estimator.} If individual units
anticipate the intervention, potential outcomes can start to diverge
before the nominal baseline {opt t0()}, biasing sigma-hat. For each
delta = 0, 1, ..., {opt maxanticip()} pre-treatment grid points,
{cmd:pathintdidrobust} shifts the reference baseline back to t0-delta and
recomputes

{center:sigma-hat(delta) = INTEGRAL_{t0-delta}^{t1} tauhat_delta(t) dt}

{pstd}
with its own standard error and confidence interval, and reports whether
the sign of the cumulative effect is robust across the full sensitivity
curve. If it is not, {cmd:pathintdidrobust} reports the conservative,
model-free bounds [min_delta sigma-hat(delta), max_delta sigma-hat(delta)]
for the true cumulative effect. This check also requires at least one
pre-treatment wave and is skipped, with a note, when none is available.

{pstd}
As with {cmd:pathintdid}, checks (A) and (C) require at least two treated
and two control units with a complete trajectory across the relevant
grid; when this fails, {cmd:pathintdidrobust} reports point estimates
only (check (A)) or marks the corresponding row "(not identified)"
(check (C)), rather than stopping with an error.


{marker options}{...}
{title:Options}

{phang}
{opt panelvar(varname)}, {opt timevar(varname)}, {opt treatvar(varname)},
{opt t0(#)}, {opt t1(#)}, and {opt level(#)} have the same meaning as in
{help pathintdid}.

{phang}
{opt maxanticip(#)} sets the number of pre-treatment grid points over
which the anticipation-robustness sensitivity curve of check (C) is
computed. The command uses min({opt maxanticip()}, P), where P is the
number of pre-treatment waves actually observed in the data. The default,
{cmd:maxanticip(0)}, skips check (C) entirely (checks (A) and (B) are
always attempted).

{phang}
{opt notable} is accepted for syntax symmetry with {cmd:pathintdid} but
currently has no effect (the diagnostic output of {cmd:pathintdidrobust}
is not a single c0(t)/c1(t)/tau(t) table and is not suppressed by this
option).


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pathintdidrobust} stores the following in {cmd:r()}. Scalars
attached to a given check are returned only when that check actually
runs (i.e., not skipped for lack of pre-treatment data or an
even/equally-spaced post-treatment grid).

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Check (A): dynamic placebo test}{p_end}
{synopt:{cmd:r(P_pre)}}number of pre-treatment waves found (0 if none){p_end}
{synopt:{cmd:r(sigma_pre)}}pre-treatment cumulative envelope{p_end}
{synopt:{cmd:r(se_sigma_pre)}}standard error of {cmd:r(sigma_pre)}{p_end}
{synopt:{cmd:r(Z_pre)}, {cmd:r(p_Z_pre)}}PCE Z-test and its p-value{p_end}
{synopt:{cmd:r(W_pre)}, {cmd:r(df_pre)}, {cmd:r(p_Wald_pre)}}joint Wald test, its df, and p-value{p_end}

{p2col 5 24 28 2: Check (B): grid-density/quadrature sensitivity}{p_end}
{synopt:{cmd:r(K_grid)}}number of post-treatment intervals used{p_end}
{synopt:{cmd:r(sigma_K)}}trapezoidal estimate on the full grid{p_end}
{synopt:{cmd:r(sigma_Khalf)}}trapezoidal estimate on the half-density grid{p_end}
{synopt:{cmd:r(sigma_Simpson)}}Simpson's 1/3-rule estimate on the full grid{p_end}

{p2col 5 24 28 2: Check (C): anticipation-robust bounding estimator}{p_end}
{synopt:{cmd:r(anticip_mmax)}}number of anticipation horizons actually used{p_end}
{synopt:{cmd:r(anticip_min)}, {cmd:r(anticip_max)}}min/max of sigma-hat(delta) across horizons{p_end}
{synopt:{cmd:r(anticipation_table)}}matrix with one row per delta and columns
sigma-hat(delta), se, CI lower, CI upper{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup: the same 20-unit training-program panel used to illustrate
{cmd:pathintdid}.{p_end}

{phang2}{cmd:. use trainingpanel, clear}{p_end}

{pstd}Full robustness suite, allowing the anticipation-robustness curve
to shift the baseline back by up to two pre-treatment grid points:{p_end}

{phang2}{cmd:. pathintdidrobust consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(4) maxanticip(2)}{p_end}

{pstd}
In the bundled {cmd:trainingpanel.dta}, the earliest recorded wave is
{cmd:time == 0}, which is exactly {opt t0()}; there are no pre-treatment
survey rounds on file, so checks (A) and (C) correctly report that no
pre-treatment data are available and skip themselves -- this is expected
behavior, not an error. Check (B), which does not require pre-treatment
waves, compares the full-grid, half-grid, and Simpson estimates of
sigma over [0,4] (an even, equally spaced 4-interval grid).{p_end}

{pstd}Requesting the same checks over the full [0,5] window, where the
number of post-treatment intervals (K=5) is odd, demonstrates that check
(B) reports a note and is skipped rather than silently using an invalid
grid:{p_end}

{phang2}{cmd:. pathintdidrobust consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) maxanticip(2)}{p_end}


{marker references}{...}
{title:References}

{phang}
Salavi, C. A-F. 2026. "Path-Integrated Difference-in-Differences (PI-DiD):
Identification, Estimation, and Inference for Cumulative Treatment
Effects." Working paper, African School of Economics.

{title:Also see}

{psee}
{help pathintdid}

{psee}
{help pathintdidplot}
