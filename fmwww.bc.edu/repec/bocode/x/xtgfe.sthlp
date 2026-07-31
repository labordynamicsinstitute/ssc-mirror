{smcl}
{* *! xtgfe version 1.5.5  July 2026  H. Ozan Eruygur}{...}
{hline}
help for {cmd:xtgfe}
{hline}

{title:Title}

{phang}
{bf:xtgfe} {hline 2} Grouped fixed-effects (GFE) estimation for panel data
(Bonhomme and Manresa, 2015, Econometrica)


{title:Syntax}

{p 8 16 2}
{cmd:xtgfe} {depvar} [{indepvars}] {ifin}{cmd:,} {opt g:roups(#)}
[{it:options}]

{p 8 16 2}
{cmd:xtgfe} {cmd:plot} [{cmd:,} {opt t:itle(string)} {opt me:ans}
{it:twoway_options}]

{p 8 16 2}
{cmd:xtgfe} {cmd:fx} [{it:newvar}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt g:roups(#)}}number of groups G; with {opt bic}, the maximum
Gmax{p_end}
{synopt:{opt tinv:ariant}}time-invariant group effects alpha(g) (default:
time-varying alpha(gt)){p_end}
{synopt:{opt het:coef(varlist|_all)}}group-specific coefficients for the
listed covariates (extension S4.2){p_end}
{synopt:{opt sub:groups(numlist)}}two-layer specification alpha(gh,t) = a(gt) +
b(gh): one subgroup count per group (extension S4.1){p_end}
{synopt:{opt bic}}select the number of groups by BIC over 1..Gmax{p_end}
{synopt:{opt refit}}with {opt bic}: re-search at the selected G and report
the better solution (not in the original codes){p_end}

{syntab:Algorithm}
{synopt:{opt alg:orithm(#)}}1 = iterative (Algorithm 1); 2 = variable
neighborhood search (Algorithm 2, default){p_end}
{synopt:{opt rand:starts(#)}}number of random starting values{p_end}
{synopt:{opt neigh:bors(#)}}maximum neighborhood size in VNS{p_end}
{synopt:{opt step:s(#)}}number of VNS sweeps per start; default 128, as in
the gretl package{p_end}
{synopt:{opt max:iter(#)}}maximum inner-loop iterations; default 1000{p_end}
{synopt:{opt ver:bose}}print the objective attained at each start{p_end}

{syntab:Standard errors}
{synopt:{opt vce(sandwich)}}large-N, large-T sandwich s.e., clustered by
unit (default){p_end}
{synopt:{opt vce(bootstrap)}}bootstrap s.e., unit resampling,
bias-corrected{p_end}
{synopt:{opt vce(fixedt)}}Pollard (1982) large-N, fixed-T analytic
s.e.{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default 100{p_end}
{synopt:{opt bstart:s(#)}}random starts per bootstrap replication; default
32{p_end}
{synopt:{opt eps:ilon(#)}}kernel bandwidth for {opt vce(fixedt)}; default:
automatic Silverman-type rule{p_end}

{syntab:Reporting}
{synopt:{opt gen:erate(newvar)}}name of the group-assignment variable;
default {cmd:gfe_group}{p_end}
{synopt:{opt long:run(varname)}}lagged dependent variable for the long-run
effects table (auto-detected by default; this option overrides){p_end}
{synopt:{opt showa:lpha}}display the estimated group effects alpha(gt){p_end}
{synopt:{opt showfreq}}additionally tabulate units per group (a compact
per-group count is always displayed){p_end}
{synoptline}

{p 4 6 2}
The data must be {cmd:xtset}. Time-series operators ({cmd:L.} etc.) and
factor variables ({cmd:i.}{it:var}, expanded to 0/1 indicators internally,
base level dropped) are allowed among the covariates. In the default model
the group effects alpha(gt) already contain a full set of group-specific
time effects, so a regressor with no cross-sectional variation {c -} time
dummies ({cmd:i.}{it:timevar}), or any aggregate time series {c -} is
perfectly collinear and is refused with an error; with {opt tinvariant}
such regressors are allowed. If you restrict the sample with {cmd:keep},
generate the lags {it:before} restricting so that their source rows are
not lost.


{title:Description}

{pstd}
{cmd:xtgfe} estimates linear panel-data models with a {it:grouped} structure
of unobserved heterogeneity, as proposed by Bonhomme and Manresa (2015). In
these models, units (countries, firms, individuals, regions, ...) are
assumed to belong to a small number of latent groups that share common time
patterns: the unobserved heterogeneity is structured into a finite number of
groups, say G, and units within the same group share a common time-varying
unobserved component. The baseline model is

{p 8 8 2}
y(it) = x(it)'theta + alpha(gi,t) + v(it),{space 6}i = 1,...,N,{space 2}t = 1,...,T,{space 6}(1)

{pstd}
where y(it) is the outcome of unit i at time t, x(it) is a vector of
observed covariates, theta is the parameter vector of interest, and v(it) is an
idiosyncratic error. The distinctive element is alpha(gi,t): gi denotes
the latent group membership of unit i, so that alpha(gi,t) is a
group-specific, {it:time-varying} effect. This structure allows for rich
patterns of unobserved heterogeneity {c -} e.g., group-specific trajectories
{c -} while avoiding the curse of dimensionality of unrestricted unit-by-time
fixed effects: instead of N*T incidental parameters, only G*T group-time
effects are estimated. Group membership gi is {it:not} observed and does
not need to be specified by the researcher: it is estimated jointly with
theta and the group-time effects by minimizing the total sum of squared
residuals over all possible groupings.

{pstd}
A nested specification allows the group effects to be constant over time,

{p 8 8 2}
y(it) = x(it)'theta + alpha(gi) + v(it),{space 6}(2)

{pstd}
that is, latent group-specific intercepts ("grouped intercepts" or clustered
fixed effects). This restricted version is requested with the
{opt tinvariant} option; comparing the fit of (1) and (2) indicates whether
the heterogeneity is genuinely time-varying.

{pstd}
This structure answers questions that standard fixed effects cannot: Which
units follow a common time pattern of unobservables (convergence clubs,
waves of democratization, common technology or policy regimes)? Who belongs
to which group, and what does each group's time profile look like? Is the
effect of x robust once time-varying grouped heterogeneity is allowed for?
How many groups does the data support ({opt bic})? Do slopes differ across
latent groups ({opt hetcoef()})? Is there an additional layer of
within-group, time-invariant heterogeneity ({opt subgroups()})?

{pstd}
Unlike unit-by-time fixed effects (infeasible) or interactive fixed effects
(which requires large T), GFE remains informative in short panels because
the heterogeneity is restricted to G groups. Under suitable regularity
conditions, BM show that the GFE estimator is consistent as both the
cross-sectional dimension N and the time dimension T grow, with the number
of groups G held fixed; the large-T part of the framework is what guarantees
that misclassification of the group assignment becomes asymptotically
negligible (T may grow much more slowly than N). Compared with a priori
classifications (by region, income, etc.), the grouping is estimated from
the data so as to maximize the explained variation of the outcome.

{pstd}
{bf:Unbalanced panels} are supported: cells with missing y or x are skipped
through the observation indicator D(it), exactly as in the authors' FORTRAN
code. Every unit needs at least one complete observation. Periods in which
{it:no} unit has a complete observation (e.g., an all-missing first period
created by lag operators) are dropped from the time grid automatically,
with a note. With time-varying effects, candidate groupings that leave a
(g,t) cell empty are discarded.

{pstd}
The command is a Stata/Mata port of the authors' Econometrica replication
codes (FORTRAN, Stata, MATLAB) and of the gretl GFE package by Lucchetti,
Pionati and Valentini. Every feature has been verified against published
numbers; see {help xtgfe##replication:Replication of published results}
below.


{title:The algorithms}

{pstd}
The GFE objective is non-convex because group membership is discrete: with
G groups and N units there are G^N possible assignments. {cmd:xtgfe}
implements the two heuristics proposed by BM (supplementary appendix S1).

{pstd}
{bf:Algorithm 1 (iterative).} Starting from a random assignment, iterate two
steps until no unit switches group: (i) {it:update}: given the assignment,
estimate theta by pooled OLS on data demeaned within group(-time) cells, and
set alpha(gt) to the cell mean of y - x'theta; (ii) {it:assignment}: given
theta and alpha, reassign every unit to the group whose time profile fits
its residual path best (minimum SSR). This is a k-means-type descent: each
step weakly lowers the objective, so it converges to a local minimum. The
procedure is repeated from {opt randstarts(#)} random assignments and the
best solution is kept. Groups that become empty are refilled with the
worst-fitting units, as in the authors' FORTRAN code.

{pstd}
{bf:Algorithm 2 (variable neighborhood search, default).} A local minimum of
Algorithm 1 is perturbed by randomly relocating n units to random groups
(n = 1, ..., {opt neighbors(#)}) and Algorithm 1 is re-run from the
perturbed assignment. If the objective improves, the new solution becomes
the incumbent and n resets to 1; otherwise n increases, widening the search.
Each of {opt steps(#)} sweeps repeats this loop, and the whole procedure is
repeated from {opt randstarts(#)} random starts. VNS is far more robust to
local minima: in replication R5 below, the default VNS search attains the
optimum that BM report from 1,000,000 starts of Algorithm 1. BM produced
Table S.XI with Algorithm 2 and the light setting (5;10;5); the gretl
package hard-codes 128 sweeps per start; {cmd:xtgfe} defaults to the gretl
depth and leaves all three parameters user-settable.

{pstd}
Because the problem is non-convex, always {cmd:set seed} for
reproducibility, and inspect {opt verbose}/{cmd:e(objs)}: if many starts
reach the same minimum, the solution is numerically reliable (this mirrors
the authors' outputobj.txt diagnostic). If the best value is attained only
rarely, increase {opt randstarts()} and {opt steps()}.


{title:Choosing the number of groups}

{pstd}
Following BM, the number of groups can be selected by minimizing the
following Bayesian information criterion, subject to an assumed maximum
value Gmax (request it with {opt bic}, where {opt groups(#)} then plays the
role of Gmax):

{p 8 8 2}
BIC(G) = SSR(G)/NT + sigma2*(G*T + N + K)/NT*ln(NT),

{pstd}
where SSR(G) is the minimized sum of squared residuals with G groups, K is
the number of regressors, and sigma2 is a consistent estimator of Var(v(it)).
Following the authors, sigma2 is computed from the largest model:

{p 8 8 2}
sigma2 = SSR(Gmax) / (NT - Gmax*T - N - K).

{pstd}
The penalty counts all estimated parameters: G*T group-time effects, N group
memberships, and K coefficients (with {opt tinvariant}, G group intercepts
replace the G*T term; in unbalanced panels NT is the number of complete
cells). {cmd:xtgfe} evaluates every G from Gmax down to 1 (G = 1 is pooled
OLS with time effects), reports the full table, stores it in {cmd:e(bic)},
and reports the model found for the minimizing G {c -} exactly as in BM's
original pipeline and in the gretl package, where the selected G's estimates
come from that G's own search during the grid. Since the search is
stochastic, the grid fit at the selected G can occasionally be a local
minimum; the {opt refit} option (an {cmd:xtgfe} addition, not present in the
original codes) runs one extra full search at the selected G and reports the
better of the two solutions. BM show that, when T grows more
slowly than N, this criterion yields an upper bound on the true number of
groups {c -} in the income-democracy application it selects G = 10 (Table
S.XI).


{marker example}{...}
{title:The empirical example used throughout}

{pstd}
All examples use the income-and-democracy application of Bonhomme and
Manresa (2015, Section 4), based on the five-year panel of Acemoglu,
Johnson, Robinson and Yared (2008). The estimated equation is the dynamic
panel model of BM, equation (22):

{p 8 8 2}
democracy(it) = theta1*democracy(it-1) + theta2*log(GDPpc)(it-1) + alpha(gi,t) + v(it)

{pstd}
that is, Acemoglu et al.'s income-democracy regression in which the country
and year fixed effects are replaced by grouped fixed effects: countries
belong to G latent groups, each with its own time path of democracy
(stable-high, stable-low, early transition, late transition, ...).

{pstd}
The examples use {cmd:Acemoglu_etal.dta}: the ready-made estimation sample
distributed with the gretl GFE package, converted to Stata format, so that
Stata and gretl users work with the {it:same} file. It is a balanced panel
of 90 countries and 7 five-year periods (1970-2000), already {cmd:xtset},
with the lags included as variables: {cmd:fhpolrigaug} is the Freedom House
political-rights index normalized to [0,1] (the democracy measure and
dependent variable); {cmd:lag_dem} is its five-year lag; {cmd:lag_income}
is the five-year lag of log real GDP per capita (Penn World Table);
{cmd:code}, {cmd:ccode} and {cmd:country} identify countries, {cmd:year}
the period. Setting up any example is therefore just:

{phang2}{cmd:. use https://eruygurakademi.com/datasets/xtgfe/Acemoglu_etal.dta, clear}{p_end}
{phang2}{cmd:. set seed 8273647}{p_end}

{pstd}
({cmd:set seed} makes the stochastic group search reproducible and is
always recommended; any number will do.) The gretl version of the data,
{cmd:Acemoglu_etal.gdt}, ships with the GFE package; it is also mirrored,
together with the Stata file, the gretl example script
{cmd:BonMan_replication.inp} and the raw data, at
{browse "https://eruygurakademi.com/datasets/xtgfe/"}.

{pstd}
{bf:How this dataset was built from the raw data} {c -} instructive if you
need to prepare a sample of your own. Starting from the raw five-year panel
{cmd:5yearpanel.dta} (same address):

{phang2}{cmd:. use https://eruygurakademi.com/datasets/xtgfe/5yearpanel.dta, clear}{p_end}
{phang2}{cmd:. xtset code_numeric year, delta(5)}{p_end}
{phang2}{cmd:. gen lag_dem = L.fhpolrigaug}{p_end}
{phang2}{cmd:. gen lag_income = L.lrgdpch}{p_end}
{phang2}{cmd:. gen byte okobs = !missing(fhpolrigaug, lag_dem, lag_income) & inrange(year,1970,2000)}{p_end}
{phang2}{cmd:. bys code_numeric: egen nok = total(okobs)}{p_end}
{phang2}{cmd:. keep if inrange(year,1970,2000) & nok==7 & samplebalancefe==1}{p_end}

{pstd}
{cmd:xtset ..., delta(5)} declares that one time step is 5 calendar years,
so that {cmd:L.} shifts by one five-year period. The two {cmd:gen} lines
create the {it:regressors of the model} {c -} a specification choice (the
model is a dynamic panel), not data cleaning; generate lags {it:before} any
{cmd:keep} so that their source rows are not lost. The
{cmd:okobs}/{cmd:nok}/{cmd:keep} lines reproduce exactly the authors'
90-country balanced sample ({cmd:samplebalancefe} is the authors' own flag
and exists only in this dataset).

{pstd}
With your own data none of this surgery is required {c -} the minimal usage
is just:

{phang2}{cmd:. use mydata, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. xtgfe y x1 x2, groups(4)}{p_end}

{pstd}
Unbalanced panels and missing cells are handled automatically (units with no
complete observation at all must be dropped; the command says so if it finds
any). A balanced panel is required only for {opt vce(fixedt)} and
{opt subgroups()}; in that case balance with:

{phang2}{cmd:. gen byte okobs = !missing(y, x1, x2)}{p_end}
{phang2}{cmd:. bys id: egen nok = total(okobs)}{p_end}
{phang2}{cmd:. su nok, meanonly}{p_end}
{phang2}{cmd:. keep if nok == r(max)}{p_end}


{title:Options with examples}

{pstd}
All examples below assume the replication sample above has been
prepared.{p_end}

{phang}
{opt groups(#)} sets the number of groups G (required). With {opt bic} it is
the maximum number Gmax over which BIC searches.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4)}{p_end}
{pmore2}
Estimates 4 latent groups. Interpretation: theta is the effect of the
covariates net of any heterogeneity following one of 4 common time paths;
the paths are in {cmd:e(alpha)} and the memberships in
{cmd:gfe_group}.{p_end}

{phang}
{opt tinvariant} restricts group effects to be constant over time
(alpha(g)).{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) tinvariant}{p_end}
{pmore2}
Interpretation: groups now differ only in level, like G "cluster dummies".
Compare its SSR with the time-varying fit: a large gap indicates that the
heterogeneity is genuinely time-varying.{p_end}

{phang}
{opt algorithm(#)}, {opt randstarts(#)}, {opt neighbors(#)}, {opt steps(#)}
and {opt maxiter(#)} control the optimizer. Defaults: algorithm 2 with
floor(8*sqrt(G)) starts, floor(sqrt(N)) neighbors and 128 VNS sweeps per
start {c -} the search depth hard-coded in the gretl package; algorithm 1
with 1024 starts (4096 when G >= 8). For reference, BM produced Table S.XI
with the much lighter setting (5 starts, 10 neighbors, 5 sweeps). Progress
dots stream while the search runs, one per random start; during {opt bic}
the percentage of the G grid completed is interleaved with the dots, and
during {opt vce(bootstrap)} one dot is shown per 10 replications.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10)}{p_end}
{pmore2}
More starts and sweeps = a more reliable global minimum at a longer run
time. Interpretation: if increasing them no longer lowers the SSR, the
reported solution is (numerically) the optimum.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) algorithm(1) randstarts(2048)}{p_end}
{pmore2}
Algorithm 1 is faster per start but more easily trapped; both BM and the
gretl manual show it can stop at a slightly higher SSR than Algorithm
2.{p_end}

{phang}
{opt verbose} prints the objective attained at each random start (also
stored in {cmd:e(objs)}); the counterpart of the authors' outputobj.txt
stability check.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) verbose}{p_end}
{pmore2}
Interpretation: the share of starts reaching the reported minimum measures
how trustworthy the solution is; a minimum found only once in many starts
calls for more searching.{p_end}

{phang}
{opt vce(sandwich)} (default) computes the large-N, large-T clustered
sandwich s.e. of BM (S3): pooled OLS of y on x and group(-time) dummies with
clustering at the unit level, conditional on the estimated grouping (same
method as the gretl package).{p_end}

{phang}
{opt vce(bootstrap)}, with {opt reps(#)} and {opt bstarts(#)}, re-estimates
the full model on samples of units drawn with replacement and adds the
squared bootstrap bias, as in BM. Per-replication coefficients are stored in
{cmd:e(bootreps)} (the authors' replications.txt).{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) vce(bootstrap) reps(100)}{p_end}
{pmore2}
Interpretation: bootstrap s.e. are BM's most conservative choice; in Table
S.XI they are 2-3 times larger than the sandwich s.e. because they also
reflect uncertainty in the estimated group assignment.{p_end}

{phang}
{opt vce(fixedt)}, optionally with {opt epsilon(#)}, computes Pollard
(1982)-type large-N, {it:fixed}-T analytic s.e. (BM section S2.2, a port of
the authors' fixedT_function.m). It corrects the sandwich formula with
kernel-weighted "frontier" terms accounting for units close to switching
groups. The bandwidth defaults to the authors' Silverman-type rule and is
reported and stored in {cmd:e(bandwidth)}. Requires a balanced panel,
time-varying effects and covariates.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) vce(fixedt)}{p_end}
{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) vce(fixedt) epsilon(0.10)}{p_end}
{pmore2}
Interpretation: fixed-T s.e. lie between the sandwich and the bootstrap
(Table S.XI, G=10: .049 < .062 < .124 for lagged democracy); they are the
theoretically preferred choice when T is short. Report sensitivity to
{opt epsilon()} as BM do in their appendix.{p_end}

{pstd}
{bf:Which vce() to use.} The three estimators differ in how much of the
uncertainty in the {it:estimated group assignment} they take into account.
{opt vce(sandwich)} conditions on the estimated grouping: it is justified by
large-N, {it:large}-T asymptotics, where misclassification vanishes; it is
the fastest, but it understates uncertainty when T is short.
{opt vce(fixedt)} keeps T fixed in the asymptotics and adds kernel-weighted
"frontier" terms for units close to the boundary between two groups, i.e.,
units that could plausibly have been assigned elsewhere; it is the
theoretically preferred choice in short panels, at the cost of requiring a
balanced panel and a bandwidth choice. {opt vce(bootstrap)} re-estimates
everything {c -} including the grouping {c -} on each resample of units, so
it captures the full sampling uncertainty; it is the most conservative (BM's
preferred cautious choice) and the slowest. The typical ordering is
sandwich < fixed-T < bootstrap: in Table S.XI at G = 10 the s.e. of lagged
democracy are .049 < .062 < .124.

{pstd}
Practical guidance: use {opt vce(sandwich)} while exploring specifications
(it is instantaneous); base final inference on {opt vce(fixedt)} when T is
short (as in most applications; T = 7 here); for referee-proof results,
report all three as BM do in Table S.XI {c -} run the command three times
with the same seed, the coefficients are identical and only the s.e. column
changes. In unbalanced panels {opt vce(fixedt)} is unavailable; use
{opt vce(bootstrap)}, as BM do. With {opt hetcoef()} or {opt subgroups()}
only {opt vce(sandwich)} is currently available. Finally, the gap between
sandwich and bootstrap s.e. is itself a diagnostic: a large gap signals that
the groups are not sharply separated, so assignment uncertainty is
substantial {c -} take the bootstrap seriously and consider a smaller G.

{phang}
{opt bic} selects the number of groups by minimizing the BIC of BM (S20)
over G = 1, ..., Gmax, using the Gmax model to estimate the error variance.
The full table is displayed and stored in {cmd:e(bic)}.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(15) bic}{p_end}
{pmore2}
Interpretation: the starred row minimizes BIC; BM show that this G is an
upper bound for the true number of groups. In the application BIC selects
G=10 (Table S.XI).{p_end}

{phang}
{opt hetcoef(varlist|_all)} makes the coefficients of the listed covariates
group-specific: y(it) = x(it)'theta(gi) + alpha(gi,t) + v(it) (BM extension
S4.2). Covariates not listed keep a common coefficient. Results are posted
as one equation per group (plus a {cmd:Common} equation), so postestimation
commands work per group. Only {opt vce(sandwich)}; not with {opt bic}.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) hetcoef(lag_income)}{p_end}
{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) hetcoef(_all)}{p_end}
{phang2}{cmd:. nlcom _b[Group1:lag_income]/(1-_b[Group1:lag_dem])}{p_end}
{pmore2}
Interpretation: tests whether the effect of income differs across latent
groups; in BM Table S16 the income coefficient ranges from .04 (low
democracy) to .12 (early transition) once both slopes are heterogeneous.
The {cmd:nlcom} line computes the group-specific cumulative (long-run)
income effect.{p_end}

{phang}
{opt subgroups(numlist)} estimates the hierarchical two-layer model
alpha(gh,t) = a(gt) + b(gh) (BM extension S4.1): G primary groups
with time-varying paths, each split into the given number of time-invariant
subgroups. The primary assignment is stored in {cmd:gfe_group}, the subgroup
in {cmd:gfe_group_sub}. Requires a balanced panel and time-varying effects;
only {opt vce(sandwich)}; not with {opt bic}.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(3) subgroups(5 2 2) showfreq}{p_end}
{pmore2}
Interpretation: BM's Table S13/Figure S6 specification: 3 dynamic patterns
(stable / early transition / late transition) with 5, 2 and 2 level shifts
within them (high ... low democracy). Use it when units share a common
dynamic but differ in levels.{p_end}

{phang}
{opt generate(newvar)} names the assignment variable (default
{cmd:gfe_group}, silently replaced when it exists). A compact units-per-group
count is always part of the output (as in gretl's {cmd:gfe_printout});
{opt showfreq} additionally shows a full tabulation.{p_end}

{phang}
{bf:Long-run effects.} When one of the covariates is the lag of the
dependent variable (a dynamic model), {cmd:xtgfe} detects it automatically
{c -} by matching its values against the within-panel one-period lag of the
dependent variable {c -} and displays, below the coefficient table, the
long-run (cumulative) effects b_k/(1 - b[lagdep]) of every other covariate
with delta-method standard errors. Use {opt longrun(varname)} to point to
the lagged dependent variable explicitly if detection is not possible
(e.g., the stored lag differs numerically). This reproduces the Cum.Income
computation in gretl's BonMan_replication.inp; the same numbers can also be
obtained with {helpb nlcom}. In static models no table is shown.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10)}{p_end}
{pmore2}
Interpretation: with lag_dem = .2772 and lag_income = .0753, the long-run
income effect is .0753/(1-.2772) = {bf:.1041} (.0088) {c -} the Cum.Income
value of BM Figure 1 and Table S.XI.{p_end}

{phang}
{opt showalpha} prints the estimated group effects: the T x G matrix
alpha(gt) with periods in rows and groups in columns (one column with
{opt tinvariant}). The same matrix is stored in {cmd:e(alpha)} and is used
by {cmd:xtgfe plot} and {cmd:xtgfe fx}.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) showalpha}{p_end}
{pmore2}
Interpretation: each column is one group's estimated time path of
unobserved heterogeneity; reading down a column shows how that group's
level of democracy (net of covariates) evolves over 1970-2000.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) generate(club) showfreq}{p_end}
{pmore2}
Interpretation: {cmd:club} identifies each country's estimated group; use it
for listings ({cmd:tab country if club==1}), maps or follow-up
regressions.{p_end}


{title:Postestimation subcommands}

{phang}
{cmd:xtgfe plot} graphs the estimated group effects from the last
estimation (the counterpart of gretl's {cmd:group_plot}). Time-varying
model: one line per group over the sample periods; {opt tinvariant}: a bar
chart. With {opt means} it instead plots the group-specific means of the
dependent variable (BM Figure 2 style). All {it:twoway_options} are passed
through.{p_end}

{phang2}{cmd:. xtgfe plot, title("Group trajectories") xlabel(1970(5)2000)}{p_end}
{phang2}{cmd:. xtgfe plot, means}{p_end}
{pmore2}
Interpretation: the alpha(gt) lines are the estimated common paths of
unobserved heterogeneity; the {opt means} version shows the raw outcome
paths by group, which is how BM present Figure 2.{p_end}

{phang}
{cmd:xtgfe fx} [{it:newvar}] generates a variable with the estimated group
effect alpha(gi,t) of every observation (the counterpart of gretl's
{cmd:group_fx}; default name {cmd:gfe_fx}).{p_end}

{phang2}{cmd:. xtgfe fx}{p_end}
{phang2}{cmd:. predict double xb0, xb}{p_end}
{phang2}{cmd:. gen double fitted = xb0 + gfe_fx}{p_end}
{phang2}{cmd:. gen double resid = fhpolrigaug - fitted}{p_end}
{pmore2}
Interpretation: {cmd:gfe_fx} is the estimated unobserved-heterogeneity
component of each observation; combined with x'theta it yields fitted values
and residuals.{p_end}


{marker replication}{...}
{title:Replication of published results}

{pstd}
Each block below reproduces a published number, so that users can verify
that {cmd:xtgfe} delivers the same values as the original software. Every
block starts from the data load in
{help xtgfe##example:The empirical example used throughout}
({cmd:Acemoglu_etal.dta}, 90 countries, 7 periods); all files are available
at {browse "https://eruygurakademi.com/datasets/xtgfe/"}.

{pstd}
{bf:R1. Baseline GFE, G = 10 {c -} BM Table S.XI / gretl manual, section 3.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) showfreq}{p_end}

{pmore}
Expected: lag_dem = {bf:.2772} (s.e. {bf:.0488}), lag_income = {bf:.0753}
(s.e. {bf:.0080}), SSR = {bf:7.74906} {c -} identical, to all printed
digits, to Table S.XI (row G = 10, first s.e. per column) and to the gretl
GFE manual.{break}
{it:In gretl:} {cmd:include GFE.gfn}, then
{cmd:open Acemoglu_etal.gdt --quiet --frompkg=GFE},
{cmd:list X = lag_dem lag_income},
{cmd:mod = gfe_estimate(fhpolrigaug, X, 10)}, {cmd:gfe_printout(mod, 1)}.{break}
{it:Original codes:} Econometrica supplementary zip (Bonhomme_Manresa_codes),
folder Application: GFE_replication_code.do with Replic = 1 (calls the
authors' FORTRAN executable), then GFE_estimates.m reproduces Table S.XI and
Figures 1-2 in MATLAB.{p_end}

{pstd}
{bf:R2. Pollard fixed-T s.e. {c -} BM Table S.XI, second s.e. per column.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) vce(fixedt)}{p_end}

{pmore}
Expected: bandwidth = {bf:.0777}; s.e. = {bf:.0623} (lag_dem) and
{bf:.0099} (lag_income), matching Table S.XI's (.062, .010).{break}
{it:In MATLAB:} fixedT_function.m called from GFE_estimates.m (epsilon grid
0.05-0.15 with the Silverman-rule pick).{p_end}

{pstd}
{bf:R3. Bootstrap s.e. {c -} BM Table S.XI, third s.e. per column.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(10) vce(bootstrap) reps(100)}{p_end}

{pmore}
Expected: s.e. of the order (.12, .015), as in Table S.XI; the exact value
is seed-dependent by the nature of the bootstrap.{break}
{it:Original codes:} Bootstrap_version.exe via GFE_replication_code.do.{p_end}

{pstd}
{bf:R4. BIC choice of G and cross-software check {c -} BM Table S.XI / gretl's BonMan_replication.inp.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(15) bic}{p_end}
{phang2}{cmd:. nlcom _b[lag_income]/(1-_b[lag_dem])}{p_end}

{pmore}
Expected (the full grid takes a few minutes): BIC is minimized at
{bf:G* = 10} (starred row: BIC .0341, SSR
{bf:7.7491}); the selected model reports lag_dem = {bf:.2772} (.0488) and
lag_income = {bf:.0753} (.0080); the cumulative income effect from
{cmd:nlcom} is {bf:.1041} (.0088). This is the Stata counterpart of the
gretl GFE package's own example script {cmd:BonMan_replication.inp}
(shipped with the package, mirrored at the address above), which runs the
identical exercise {c -} {cmd:gfe_estimate(fhpolrigaug, X, 15)} with
{cmd:BICselect=1} {c -} and returns G* = 10, obj = 7.74906 and Cum.Income =
0.104117 (0.0088), i.e., the same values. Seeds are software-specific
(different RNGs), but both programs converge to the same optimum; if a run
stops slightly above SSR 7.749, increase {opt randstarts()}/{opt steps()}
(or, in {cmd:xtgfe}, add the {opt refit} option).{p_end}

{pstd}
{bf:R5. Heterogeneous coefficients {c -} BM Table S16.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) hetcoef(lag_income)}{p_end}

{pmore}
Expected (top panel of Table S16): common lag_dem = {bf:.288} (.056);
group-specific lag_income = {bf:(.103, .047, .087, .082)} up to group
relabeling; SSR = 14.179.{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(4) hetcoef(_all)}{p_end}

{pmore}
Expected (bottom panel of Table S16, up to relabeling): (lag_dem, lag_income)
pairs {bf:(.644, .070) (.319, .041) (.016, .122) (.248, .090)} with s.e.
(.077, .019) (.113, .014) (.081, .022) (.097, .018); SSR = 13.540. BM
obtained this with 1,000,000 starts of Algorithm 1; 24 VNS starts
suffice.{break}
{it:In MATLAB:} Heterogeneous_coefficientsA.m / Heterogeneous_coefficientsB.m
in the Application folder of the supplementary zip.{p_end}

{pstd}
{bf:R6. Two-layer specification {c -} BM Table S13 / Figure S6.}{p_end}

{phang2}{cmd:. xtgfe fhpolrigaug lag_dem lag_income, groups(3) subgroups(5 2 2) showfreq}{p_end}
{phang2}{cmd:. xtgfe plot, xlabel(1970(5)2000)}{p_end}

{pmore}
Expected: SSR = {bf:11.702}; primary group sizes {bf:(64, 13, 13)} =
"Stable", "Early transition", "Late transition" in Table S13's two-layer
column; the plot reproduces the 9 fine trajectories of Figure S6.{break}
{it:In MATLAB:} GFE_twolayers_computation.m /
GFE_twolayers_estimates.m.{p_end}


{title:Stored results}

{pstd}{cmd:xtgfe} stores the following in {cmd:e()} (with covariates):{p_end}

{synoptset 22 tabbed}{...}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and VCV (one equation per group
with {opt hetcoef()}){p_end}
{synopt:{cmd:e(alpha)}}group effects: T x G (time-varying), G x 1
(time-invariant), or T x S fine trajectories (two-layer){p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(ll)}}minimized SSR and Gaussian
log-likelihood{p_end}
{synopt:{cmd:e(G)}, {cmd:e(N_units)}, {cmd:e(T)}}number of groups and panel
dimensions{p_end}
{synopt:{cmd:e(algorithm)}}algorithm actually used (1 or 2){p_end}
{synopt:{cmd:e(randstarts)}, {cmd:e(neighbors)}, {cmd:e(steps)}}search settings actually used{p_end}
{synopt:{cmd:e(objs)}}objective attained at each random start (not with
{opt bic}){p_end}
{synopt:{cmd:e(etime)}}elapsed estimation time, in seconds{p_end}
{synopt:{cmd:e(bic)}}BIC table (G, BIC, SSR), with {opt bic}{p_end}
{synopt:{cmd:e(bandwidth)}}kernel bandwidth, with {opt vce(fixedt)}{p_end}
{synopt:{cmd:e(bootreps)}}per-replication coefficients, with
{opt vce(bootstrap)}{p_end}
{synopt:{cmd:e(Kc)}, {cmd:e(hetvars)}}with {opt hetcoef()}: number of common
coefficients; list of group-specific covariates{p_end}
{synopt:{cmd:e(S)}, {cmd:e(H)}}with {opt subgroups()}: total fine-group count; subgroup counts per group{p_end}
{synopt:{cmd:e(a_primary)}, {cmd:e(b_sub)}}with {opt subgroups()}: effect components a(gt) and b(gh){p_end}
{synopt:{cmd:e(subgroupvar)}}with {opt subgroups()}: subgroup variable name{p_end}
{synopt:{cmd:e(tvals)}}time values of the estimation window{p_end}
{synopt:{cmd:e(timevar)}, {cmd:e(panelvar)}, {cmd:e(groupvar)}}identifier variable names{p_end}

{pstd}
The estimated group of each unit is stored in the variable given by
{opt generate()} ({cmd:gfe_group} by default; plus {cmd:gfe_group_sub} with
{opt subgroups()}). Without covariates, group effects are saved in the
global matrix {cmd:xtgfe_alpha}.


{title:References}

{phang}
Acemoglu, D., S. Johnson, J. A. Robinson, and P. Yared (2008). Income and
democracy. {it:American Economic Review} 98(3): 808-842.

{phang}
Bonhomme, S. and E. Manresa (2015). Grouped patterns of heterogeneity in
panel data. {it:Econometrica} 83(3): 1147-1184; Supplementary Appendix and
replication codes.

{phang}
Lucchetti, R., A. Pionati and F. Valentini (2026). Grouped Fixed Effects
estimators in gretl: the GFE package, version 0.1.

{phang}
Pollard, D. (1982). A central limit theorem for k-means clustering.
{it:Annals of Probability} 10(4): 919-926.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye.{break}
{browse "https://www.eruygurakademi.com"}{break}
eruygurakademi@gmail.com

{pstd}
{bf:xtgfe} v1.5.5 {c -} July 2026

{pstd}
The estimator implemented here was proposed by Stephane Bonhomme (University
of Chicago) and Elena Manresa in Bonhomme and Manresa (2015). {bf:xtgfe} is
a Stata/Mata port of the authors' Econometrica replication codes (FORTRAN,
Stata and MATLAB, including fixedT_function.m and the extension codes) and
of the gretl GFE package by Riccardo (Jack) Lucchetti, Alessandro Pionati
and Francesco Valentini. All results were verified against the published
values in the paper's supplementary appendix (Tables S.XI, S13, S16) and in
the gretl package documentation.

{title:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:xtgfe}: Grouped fixed effects estimation for panel
data (Bonhomme and Manresa, 2015). Stata package version 1.5.5. Available
from: {browse "https://www.eruygurakademi.com"}.
