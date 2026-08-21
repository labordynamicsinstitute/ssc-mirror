{smcl}
{* *! version 1.0.0  19aug2026}{...}
{vieweralsosee "xttvpivmg methods" "help xttvpivmg_methods"}{...}
{vieweralsosee "xttvpivmg postestimation" "help xttvpivmg_postestimation"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{vieweralsosee "ivregress" "help ivregress"}{...}
{viewerjumpto "Syntax" "xttvpivmg##syntax"}{...}
{viewerjumpto "Description" "xttvpivmg##description"}{...}
{viewerjumpto "The estimator" "xttvpivmg##estimator"}{...}
{viewerjumpto "Options" "xttvpivmg##options"}{...}
{viewerjumpto "Bandwidth selection" "xttvpivmg##bandwidth"}{...}
{viewerjumpto "Interpreting the output" "xttvpivmg##output"}{...}
{viewerjumpto "Remarks and practical guidance" "xttvpivmg##remarks"}{...}
{viewerjumpto "Limitations" "xttvpivmg##limits"}{...}
{viewerjumpto "Examples" "xttvpivmg##examples"}{...}
{viewerjumpto "Stored results" "xttvpivmg##results"}{...}
{viewerjumpto "References" "xttvpivmg##refs"}{...}
{viewerjumpto "Author" "xttvpivmg##author"}{...}

{title:Title}

{phang}
{bf:xttvpivmg} {hline 2} Time-varying parameter instrumental-variable mean-group
estimation of large heterogeneous panels with endogenous regressors


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:xttvpivmg}
{depvar}
[{it:exogvars}]
{cmd:(}{it:endogvars} {cmd:=} {it:instruments}{cmd:)}
{ifin}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Kernel}
{synopt:{opth k:ernel(string)}}{cmd:gaussian} (default), {cmd:epanechnikov},
{cmd:rectangle} or {cmd:exponential}{p_end}
{synopt:{opt expp:arm(c a)}}parameters of the exponential kernel K(x)=exp(-c*x^a);
default {cmd:1 1}{p_end}

{syntab:Bandwidth}
{synopt:{opt h(#)}}second-stage bandwidth exponent: H = T^{it:#}; default {cmd:0.5}{p_end}
{synopt:{opt l(#)}}first-stage bandwidth exponent: L = T^{it:#}; default = {opt h()}{p_end}
{synopt:{opt bw(#)}}second-stage bandwidth H directly, in periods{p_end}
{synopt:{opt bwf:irst(#)}}first-stage bandwidth L directly, in periods{p_end}
{synopt:{opt cv}}choose (H,L) by leave-one-unit-out cross-validation{p_end}
{synopt:{opt hg:rid(numlist)}}CV grid for h; default {cmd:0.30(0.05)0.85}{p_end}
{synopt:{opt lg:rid(numlist)}}CV grid for l; default {cmd:0.30(0.05)0.85}{p_end}
{synopt:{opt cvd:ivisor(string)}}{cmd:n} (default, as printed by BMK) or {cmd:nminus1}{p_end}
{synopt:{opt nocvt:rim}}evaluate the CV objective over all t, not the trimmed interior{p_end}

{syntab:Sample and model}
{synopt:{opt tr:im(#)}}report t = {it:#}+1,...,T-{it:#}; default {it:#} = floor(H){p_end}
{synopt:{opt notrim:ming}}report every t, including boundary points{p_end}
{synopt:{opt dem:ean(string)}}{cmd:none} (default), {cmd:fixed} or {cmd:tv};
see {help xttvpivmg##remarks:Remark 1}{p_end}
{synopt:{opt nocon:stant}}suppress the constant in x and z{p_end}

{syntab:Reporting}
{synopt:{opt vce(string)}}{cmd:paper} (default, divisor N^2) or {cmd:mg} (divisor N(N-1)){p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt at(numlist)}}dates at which to tabulate the paths{p_end}
{synopt:{opt tref(#)}}date whose estimates go into {cmd:e(b)}/{cmd:e(V)}; default mid-window{p_end}
{synopt:{opt sum:mary}}add a summary table of the estimated paths{p_end}
{synopt:{opt full}}also store the per-unit paths in {cmd:e(bi)}{p_end}

{syntab:Graphs}
{synopt:{opt gr:aph}}plot each coefficient path with its confidence band{p_end}
{synopt:{opt cvp:lot}}plot the cross-validation surface (requires {opt cv}){p_end}
{synopt:{opt name(string)}}stub for the graph names; default {cmd:tvpivmg}{p_end}
{synopt:{opt comb:ine}}force {helpb graph combine} even for a single regressor{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
The data must be {helpb xtset} with both a panel and a time variable, and the
estimation sample must be a {bf:balanced, gap-free} rectangle.{p_end}
{p 4 6 2}
{it:depvar}, {it:exogvars}, {it:endogvars} and {it:instruments} may all contain
time-series operators.{p_end}
{p 4 6 2}
{cmd:xttvpivmg} may be replayed, and supports {helpb xttvpivmg_postestimation##predict:predict}.{p_end}


{marker description}{title:Description}

{pstd}
{cmd:xttvpivmg} implements the time-varying parameter instrumental-variable
mean-group (TVP-IV-MG) estimator of {help xttvpivmg##BMK2026:Bai, Marcellino and
Kapetanios (2026)} for large heterogeneous panels in which

{p 8 8 2}(a) the slope coefficients differ across units, {bf:and}{p_end}
{p 8 8 2}(b) those coefficients {bf:change smoothly over time}, {bf:and}{p_end}
{p 8 8 2}(c) some regressors are {bf:endogenous}.{p_end}

{pstd}
The object estimated is not a scalar coefficient but a {bf:path}: the
cross-sectional mean coefficient vector b0(t) = E(b_it) at every date t. The
estimator is fully non-parametric in the time dimension {hline 2} no state-space
model, no Kalman filter, no assumed break dates, no functional form for the
time variation beyond smoothness.

{pstd}
Mechanically it is the time-series estimator of {help xttvpivmg##GKM2021:Giraitis,
Kapetanios and Marcellino (2021)} run separately on each panel unit, then averaged
across units in the manner of {help xttvpivmg##PS1995:Pesaran and Smith (1995)}.
That structure is what makes inference simple: the sampling error of the kernel IV
step vanishes relative to the coefficient heterogeneity, so the standard errors are
just the cross-sectional dispersion of the N unit-level paths. There is no HAC
correction and no bootstrap.

{pstd}
See {bf:{help xttvpivmg_methods:help xttvpivmg methods}} for the full
equation-by-equation derivation and the mapping from each block of code to the
paper's numbered equations.


{marker estimator}{title:The estimator}

{pstd}
The model is (BMK eq. 1-2), for i = 1,...,N and t = 1,...,T:

{p 8 8 2}{bf:y_it = x_it'b_it + u_it}{p_end}
{p 8 8 2}{bf:x_it = P_it'z_it + v_it}{p_end}

{pstd}
where x_it is k x 1 (one element being a constant), z_it is p x 1 with p >= k, and
P_it is the p x k first-stage matrix. Coefficients follow the random-coefficient
decomposition b_it = b0(t) + e_it, with b0(t) a deterministic Holder-continuous
path and e_it a mean-zero, smooth, persistent random deviation.

{pstd}
Estimation proceeds in four steps.

{p 4 8 2}{bf:1. Kernel weights} (eq. 5). b_j,t(H) = K(|j-t|/H) for the second stage
and b_j,t(L) = K(|j-t|/L) for the first stage. H and L are allowed to differ and
generally should.

{p 4 8 2}{bf:2. First stage} (eq. 4). For each unit i and each date t, a
kernel-weighted local projection of x on z gives Phat_it.

{p 4 8 2}{bf:3. Second stage} (eq. 3). bhat^IV_it is a kernel-weighted IV
regression of y on x using Phat'z as the instrument block. Critically, the
first-stage matrix is evaluated {bf:at the summation index j}, not at the
evaluation point t.

{p 4 8 2}{bf:4. Mean group} (eq. 8). bhat_MG(t) is the simple average across
units of bhat^IV_it, with variance from eq. (17).

{pstd}
Pointwise 95% confidence bands are bhat(t) +/- 1.96*se(bhat(t)), exactly as in the
paper's Figure 1.


{marker options}{title:Options}

{dlgtab:Kernel}

{phang}
{opth kernel(string)} selects the kernel K(.) in eq. (5). Allowed values are
{cmd:gaussian} (the default; K(x)=exp(-x^2/2)), {cmd:epanechnikov}
(K(x)=0.75(1-x^2)I{c 123}|x|<=1{c 125}), {cmd:rectangle} (also {cmd:uniform};
K(x)=0.5*I{c 123}|x|<=1{c 125}) and {cmd:exponential} (K(x)=exp(-c*x^a)).
Multiplicative constants cancel in the estimator and have no numerical effect.

{phang}
The Gaussian kernel has {bf:unbounded support}: every observation contributes at
every date, with geometrically declining weight. The Epanechnikov and rectangle
kernels truncate hard at |j-t| <= H. BMK's Monte Carlo finds the Gaussian kernel
gives the lowest MAD, and it is the kernel used in their empirical application.

{phang}
{opt expparm(c a)} supplies c and a for the exponential kernel. Ignored otherwise.

{dlgtab:Bandwidth}

{phang}
{opt h(#)} and {opt l(#)} set the bandwidths through the exponent parameterisation
H = T^h, L = T^l used throughout the literature. {opt h(0.5)} reproduces the
rule-of-thumb H = sqrt(T) recommended by Giraitis, Kapetanios and Yates (2018) and
used as the benchmark in BMK's Monte Carlo. If {opt l()} is omitted it defaults to
{opt h()}, giving the paper's H = L = T^0.5 rule of thumb.

{phang}
{opt bw(#)} and {opt bwfirst(#)} set H and L directly in periods instead. The
corresponding exponents are reported.

{phang}
{opt cv} selects (H,L) jointly by the leave-one-unit-out cross-validation of BMK
section 2.3. This is a {bf:two-dimensional} search: H and L are chosen
independently, and in the paper's own application they came out very different
(H = T^0.65, L = T^0.30). See {help xttvpivmg##bandwidth:Bandwidth selection} below.

{phang}
{opt hgrid(numlist)} and {opt lgrid(numlist)} give the search grids in exponent
units. The default 0.30(0.05)0.85 is the grid of BMK's empirical application;
their Monte Carlo used the coarser 0.3(0.1)0.7.

{phang}
{opt cvdivisor(string)} controls the leave-one-out average. BMK print
bhat^{c 123}-i{c 125}(t) = (1/N)*sum_{c 123}j!=i{c 125} bhat_j(t), i.e. divisor
{cmd:n} {hline 2} the default here, for faithfulness. The usual convention (and
that of Sun, Carroll and Li 2009, from which the procedure is adapted) is divisor
{cmd:nminus1}. The choice shifts the CV objective but rarely the selected
bandwidth; try both if the selection sits on a grid boundary.

{phang}
{opt nocvtrim} evaluates the CV objective over all t rather than the trimmed
interior. BMK write the objective as a sum over t = 1,...,T but evaluate all their
reported statistics on the trimmed window. Trimming the CV as well (the default
here) prevents boundary bias from driving the bandwidth choice.

{dlgtab:Sample and model}

{phang}
{opt trim(#)} and {opt notrimming} control the reported window. Theorem 1(ii) of
BMK is an {bf:interior-point} result: at dates near 1 or T the kernel is
one-sided and the estimates are biased. The default reports
t = floor(H)+1,...,T-floor(H), matching the window over which BMK compute MAD and
coverage. {opt notrimming} reports everything, boundary included {hline 2} useful
for diagnostics, not for inference.

{phang}
{opt demean(string)} implements BMK Remark 1. {cmd:none} (default) is Remark 1(a):
the constant sits in x and its coefficient is itself a time-varying fixed effect.
{cmd:fixed} is Remark 1(b) with a time-invariant effect: y and x are residualised
on a unit-specific constant. {cmd:tv} is Remark 1(b) with a time-varying effect:
the residualisation is itself kernel-smoothed at bandwidth L. Both non-default
choices remove the intercept, so {opt noconstant} is imposed automatically.

{phang}
{opt noconstant} omits the constant from both x and z. The model in eq. (1)
explicitly includes a constant among the regressors, so this is rarely what you
want unless you are also demeaning.

{dlgtab:Reporting}

{phang}
{opt vce(string)} selects the variance divisor. {cmd:paper} (default) is eq. (17)
exactly: Sigmahat_e(t) uses divisor N and Var(bhat_MG(t)) = Sigmahat_e(t)/N, so
the effective divisor is N^2. {cmd:mg} uses the conventional Pesaran-Smith
mean-group divisor N(N-1), which is slightly larger and more conservative in small
N. The difference is a factor (N-1)/N in the variance; with N = 19 that is about
2.7% in the standard error.

{phang}
{opt at(numlist)} tabulates the paths at the given dates (in {it:timevar} units)
instead of at nine evenly spaced points. Every requested date must lie inside the
reported window.

{phang}
{opt tref(#)} chooses which date's estimates are posted to {cmd:e(b)} and
{cmd:e(V)}, so that {helpb test}, {helpb lincom} and {helpb nlcom} operate at that
date. The default is the middle of the reported window.

{phang}
{opt summary} adds a table giving, for each regressor, the mean, minimum, maximum
and standard deviation of the estimated path plus the share of dates at which it is
significant at 5%. This is {bf:descriptive}: BMK provide no inference for
time-averaged coefficients, and none is invented here.

{phang}
{opt full} additionally stores the N per-unit paths in {cmd:e(bi)}, stacked
unit-major over the reported window. Skipped with a note if N times the number of
reported dates exceeds 10,000 rows.

{dlgtab:Graphs}

{phang}
{opt graph} draws one panel per regressor: the point estimate as a solid line, the
pointwise confidence band as a shaded area, and a zero reference line. Panels are
combined into a single figure in the style of BMK Figure 1. {opt name(string)}
sets the name stub; individual panels are {it:stub}{cmd:_1}, {it:stub}{cmd:_2},
... and the combined figure is {it:stub}.

{phang}
{opt cvplot} draws the cross-validation surface over the (h,l) grid, with marker
size inversely proportional to the CV objective. Requires {opt cv}.


{marker bandwidth}{title:Bandwidth selection}

{pstd}
The bandwidth is the one genuinely consequential tuning choice, and BMK's Monte
Carlo is unambiguous that cross-validation beats the rule of thumb: with the
Gaussian kernel at N=50, T=500 the CV estimator of the autoregressive coefficient
has average MAD 0.039 against 0.069, and coverage 0.823 against 0.574.

{pstd}
Three practical points.

{phang}
{bf:1. T must grow faster than N.} Pointwise asymptotic normality requires
(H/T)^g2 = o(N^{c 94}(-1/2)), so sqrt(N)/T^{c 94}(g2(1-h)) must go to zero. In BMK's
simulations coverage improves with T but {bf:deteriorates with N} for fixed T {hline 2}
at N=50, T=100 the rule-of-thumb coverage for the AR coefficient falls to 0.496.
If your N is comparable to your T, treat the confidence bands with suspicion.

{phang}
{bf:2. CV is expensive.} Estimation is O(N*T^2) per (H,L) pair, and the default
grid has 144 pairs. The implementation reuses the first stage across the h-grid, so
the cost is roughly (number of l values) first-stage passes plus 144 second-stage
passes, but on a large panel this is still minutes rather than seconds.

{phang}
{bf:3. The selected pair may violate Assumption 2.6.} BMK's Assumption 2.6
requires H = o(L/(log T)^{c 94}max(1,2/a)), i.e. H of {bf:smaller} order than L. Yet
the CV in their own empirical application selects H = T^0.65 and L = T^0.30, which
is the opposite ordering. This is a genuine and unresolved tension in the paper.
{cmd:xttvpivmg} does not constrain the grid to hide it: if CV selects h > l, that
is reported as-is and you should say so in your write-up.


{marker output}{title:Interpreting the output}

{pstd}
{bf:The header} reports N, T, the kernel, both bandwidths in periods and in
exponent form, how they were chosen, the variance convention, and the trimming
window.

{pstd}
{bf:The coefficient blocks.} One block per regressor, with rows for the tabulated
dates. Within a block:

{p2colset 8 26 28 2}{...}
{p2col :{bf:Coef.}}bhat_MG(t), the cross-sectional mean coefficient at date t (eq. 8){p_end}
{p2col :{bf:Std. Err.}}sqrt(Sigmahat_e(t)[j,j]/N) from eq. (17){p_end}
{p2col :{bf:z}}Coef./Std. Err.; asymptotically standard normal by Theorem 1(ii){p_end}
{p2col :{bf:P>|z|}}two-sided pointwise p-value{p_end}
{p2col :{bf:Conf. Int.}}pointwise interval, {bf:not} a uniform band{p_end}
{p2colreset}{...}

{pstd}
{bf:Read the path, not the rows.} A single date's coefficient is rarely the object
of interest. What the estimator is for is the {it:shape}: when a coefficient
becomes significant, whether it is trending, whether it turns. Use {opt graph}.

{pstd}
{bf:"Pointwise" is a real caveat.} Each interval covers b0(t) with probability
1-alpha at that single t. The probability that the band covers the {it:whole path}
simultaneously is much lower. BMK provide no uniform band, so do not describe the
shaded region as one.

{pstd}
{bf:Standard errors measure heterogeneity, not fit.} Because the asymptotic
expansion collapses to (1/sqrt(N))*sum_i e_it, the standard error at date t is
driven entirely by how much the N unit-level estimates disagree at t. A tight band
means the units agree; it does not mean each unit's regression fits well.


{marker remarks}{title:Remarks and practical guidance}

{pstd}
{bf:Which regressors go in the parentheses.} Everything inside is projected through
the first stage; everything outside instruments itself. In BMK's own empirical
application {it:all four} regressors (constant, lagged inflation, unemployment and
lead inflation) are treated as endogenous with respect to a separate instrument
set, so they all go inside. Putting a genuinely exogenous regressor inside is not
an error {hline 2} it is projected on a set containing itself, which returns it
{hline 2} but it wastes computation.

{pstd}
{bf:Dynamic panels are allowed.} BMK Remark 4 licenses a lagged dependent variable
as a weakly exogenous regressor, citing Hsiao, Pesaran and Tahmiscioglu (1999);
their own Monte Carlo and application both include one. Write it as
{cmd:L.}{it:depvar} in {it:exogvars} or inside the parentheses as you prefer.

{pstd}
{bf:Correlated random coefficients are fine.} Unusually for a mean-group
estimator, consistency does {bf:not} require E(e_i|x_it) = 0. The smoothness
condition on e_it does the work instead, so the estimator survives correlated
random coefficients {hline 2} a case in which the standard MG estimator is
inconsistent. BMK's Monte Carlo deliberately builds this in.

{pstd}
{bf:It is a smoother, not a filter.} The kernel is two-sided: bhat(t) uses
observations both before and after t. These are not real-time estimates and must
not be interpreted as what an agent could have known at t.

{pstd}
{bf:Sample-size regime.} BMK simulate N in {c 123}10,20,50{c 125} and T in
{c 123}100,200,500{c 125}. Outside that region, and especially when N approaches
or exceeds T, the pointwise normal approximation degrades in a direction that
{it:understates} uncertainty.

{pstd}
{bf:Singular systems.} If the second-stage k x k matrix is singular for some
unit-date pair, that unit is dropped from the mean-group average at that date and
the number of such drops is reported. A large count usually means weak instruments
locally, too small an H, or a near-collinear regressor set.

{pstd}
{bf:Validating against an independent implementation.} The per-unit paths are
exactly the time-series estimator of Giraitis, Kapetanios and Marcellino (2021).
The gretl package {bf:ketvals} (Valentini and Lucchetti) implements that estimator
independently; running its {cmd:tv_IV} on each unit and averaging the N paths by
hand reproduces {cmd:e(bmg)}. Note that {bf:ketvals} reports the {it:time-series}
sandwich variance, which is a different object from eq. (17) and will not match
{cmd:e(semg)}.


{marker limits}{title:Limitations}

{pstd}
These are properties of the method, not of the implementation, and are stated here
rather than papered over.

{phang}
{bf:No cross-sectional dependence.} Assumption 2.2 requires regressors, errors and
random coefficients to be independent across units. There is no common-factor or
CCE variant of this estimator. If your panel has strong CSD, the mean-group
variance in eq. (17) is not valid. Test for it first ({helpb xtcd2}, or
{helpb xttestpanel} if installed).

{phang}
{bf:No test of parameter constancy.} BMK provide no test of H0: b0(t) = b0. The
visual evidence from {opt graph} is not a test, and none is supplied here.

{phang}
{bf:No uniform confidence band.} Pointwise only.

{phang}
{bf:No weak-instrument diagnostic.} The paper offers none for the time-varying
case. Per-period Hausman and Sargan statistics {it:do} exist in Giraitis,
Kapetanios and Marcellino (2021) for the time-series case, but they are not part
of BMK and are not implemented here.

{phang}
{bf:Balanced panels only.} The kernel sums run over j = 1,...,T and assume a
complete regular rectangle. Use {helpb tsfill} or drop short units.


{marker examples}{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}{bf:Rule of thumb H = L = T^0.5, one endogenous regressor}{p_end}
{phang2}{cmd:. xttvpivmg invest kstock (mvalue = L.mvalue L2.mvalue)}{p_end}

{pstd}{bf:Same, with the coefficient paths plotted}{p_end}
{phang2}{cmd:. xttvpivmg invest kstock (mvalue = L.mvalue L2.mvalue), graph}{p_end}

{pstd}{bf:Different bandwidths for the two stages}{p_end}
{phang2}{cmd:. xttvpivmg invest kstock (mvalue = L.mvalue L2.mvalue), h(0.65) l(0.30)}{p_end}

{pstd}{bf:Data-driven bandwidths by leave-one-unit-out cross-validation}{p_end}
{phang2}{cmd:. xttvpivmg invest kstock (mvalue = L.mvalue L2.mvalue), cv graph cvplot}{p_end}

{pstd}{bf:The hybrid Phillips curve of BMK section 4}{p_end}
{phang2}{cmd:. xtset country month}{p_end}
{phang2}{cmd:. xttvpivmg inf (L.inf urate F.inf = L2.inf L3.inf L4.inf L.urate L2.urate), ///}{p_end}
{phang2}{cmd:      cv kernel(gaussian) graph summary}{p_end}

{pstd}
Note that all three substantive regressors sit inside the parentheses, because in
BMK's specification lead inflation is endogenous by construction and the remaining
regressors are instrumented by their own further lags.

{pstd}{bf:Epanechnikov kernel, no trimming, conservative variance}{p_end}
{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), kernel(epan) notrimming vce(mg)}{p_end}

{pstd}{bf:Tabulate at chosen dates and post that date to e(b)}{p_end}
{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), at(1995 2000 2005 2010) tref(2005)}{p_end}
{phang2}{cmd:. test x1}{p_end}

{pstd}{bf:Time-varying fixed effects (Remark 1(b))}{p_end}
{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), demean(tv) l(0.4)}{p_end}

{pstd}{bf:Recover the paths for your own graph or table}{p_end}
{phang2}{cmd:. matrix B = e(bmg)}{p_end}
{phang2}{cmd:. matrix S = e(semg)}{p_end}
{phang2}{cmd:. matrix D = e(tlist)}{p_end}

{pstd}
A complete, self-contained demonstration that simulates BMK's own Monte Carlo
design and checks that the estimator recovers the true coefficient paths is
supplied in {bf:xttvpivmg_example.do}. Retrieve it with
{cmd:net get xttvpivmg} and run it with {cmd:do xttvpivmg_example.do}.


{marker results}{title:Stored results}

{pstd}{cmd:xttvpivmg} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panel units, N{p_end}
{synopt:{cmd:e(T)}}number of time periods, T{p_end}
{synopt:{cmd:e(k_x)}}number of regressors k (including the constant){p_end}
{synopt:{cmd:e(p_z)}}number of instruments p (including the constant){p_end}
{synopt:{cmd:e(H)}}second-stage bandwidth in periods{p_end}
{synopt:{cmd:e(L)}}first-stage bandwidth in periods{p_end}
{synopt:{cmd:e(hexp)}}h such that H = T^h{p_end}
{synopt:{cmd:e(lexp)}}l such that L = T^l{p_end}
{synopt:{cmd:e(trim)}}number of dates trimmed at each end{p_end}
{synopt:{cmd:e(nrep)}}number of dates reported{p_end}
{synopt:{cmd:e(tref)}}date posted to {cmd:e(b)}/{cmd:e(V)}{p_end}
{synopt:{cmd:e(nsing)}}number of singular unit-date systems dropped{p_end}
{synopt:{cmd:e(cvmin)}}minimised CV objective (with {opt cv}){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xttvpivmg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(exogvars)}}included exogenous regressors{p_end}
{synopt:{cmd:e(endogvars)}}endogenous regressors{p_end}
{synopt:{cmd:e(insts)}}excluded instruments{p_end}
{synopt:{cmd:e(xnames)}}column names of {cmd:e(bmg)}{p_end}
{synopt:{cmd:e(znames)}}full instrument list{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(kernel)}}kernel used{p_end}
{synopt:{cmd:e(bwsel)}}how the bandwidths were chosen{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:paper} or {cmd:mg}{p_end}
{synopt:{cmd:e(demean)}}{cmd:none}, {cmd:fixed} or {cmd:tv}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xttvpivmg_p}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficients at {cmd:e(tref)}{p_end}
{synopt:{cmd:e(V)}}(diagonal) variance at {cmd:e(tref)}{p_end}
{synopt:{cmd:e(bmg)}}{it:nrep} x k matrix of mean-group coefficient paths{p_end}
{synopt:{cmd:e(semg)}}{it:nrep} x k matrix of standard errors{p_end}
{synopt:{cmd:e(tlist)}}{it:nrep} x 1 vector of dates, aligned with the rows above{p_end}
{synopt:{cmd:e(bi)}}(N*{it:nrep}) x k per-unit paths, unit-major (with {opt full}){p_end}
{synopt:{cmd:e(cvobj)}}CV objective at each grid point (with {opt cv}){p_end}
{synopt:{cmd:e(cvgrid)}}the (h,l) grid, aligned with {cmd:e(cvobj)} (with {opt cv}){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
{cmd:e(b)} and {cmd:e(V)} hold a single date so that {helpb test} and
{helpb lincom} work; the paths in {cmd:e(bmg)} are the estimator's actual output.


{marker refs}{title:References}

{marker BMK2026}{...}
{phang}
Bai, Y., M. Marcellino and G. Kapetanios. 2026. Mean group instrumental variable
estimation of time-varying large heterogeneous panels with endogenous regressors.
{it:Econometrics and Statistics} 37: 26-41.
{browse "https://doi.org/10.1016/j.ecosta.2023.06.004":doi:10.1016/j.ecosta.2023.06.004}

{marker GKM2021}{...}
{phang}
Giraitis, L., G. Kapetanios and M. Marcellino. 2021. Time-varying instrumental
variable estimation. {it:Journal of Econometrics} 224(2): 394-415.
{browse "https://doi.org/10.1016/j.jeconom.2020.08.013":doi:10.1016/j.jeconom.2020.08.013}

{phang}
Giraitis, L., G. Kapetanios and T. Yates. 2014. Inference on stochastic
time-varying coefficient models. {it:Journal of Econometrics} 179(1): 46-65.

{phang}
Giraitis, L., G. Kapetanios and T. Yates. 2018. Inference on multivariate
heteroscedastic time varying random coefficient models. {it:Journal of Time Series
Analysis} 39(2): 129-149.

{phang}
Dendramis, Y., L. Giraitis and G. Kapetanios. 2021. Estimation of time-varying
covariance matrices for large datasets. {it:Econometric Theory} 37(6): 1100-1134.

{phang}
Lucchetti, R. and F. Valentini. 2023. Kernel-based time-varying IV estimation:
handle with care. {it:Empirical Economics} 65(6): 3001-3026.
{browse "https://doi.org/10.1007/s00181-023-02450-6":doi:10.1007/s00181-023-02450-6}

{marker PS1995}{...}
{phang}
Pesaran, M. H. and R. Smith. 1995. Estimating long-run relationships from dynamic
heterogeneous panels. {it:Journal of Econometrics} 68(1): 79-113.
{browse "https://doi.org/10.1016/0304-4076(94)01644-F":doi:10.1016/0304-4076(94)01644-F}

{phang}
Hsiao, C. and M. H. Pesaran. 2008. Random coefficient models. In {it:The
Econometrics of Panel Data}, ed. L. Matyas and P. Sevestre, 185-213. Berlin:
Springer.

{phang}
Sun, Y., R. J. Carroll and D. Li. 2009. Semiparametric estimation of fixed-effects
panel data varying coefficient models. {it:Advances in Econometrics} 25: 101-129.
{browse "https://doi.org/10.1108/S0731-9053(2009)0000025006":doi:10.1108/S0731-9053(2009)0000025006}

{phang}
Gali, J. and M. Gertler. 1999. Inflation dynamics: A structural econometric
analysis. {it:Journal of Monetary Economics} 44(2): 195-222.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}

{pstd}
Bug reports and suggestions are welcome.


{title:Also see}

{psee}
Manual: {helpb xtset}, {helpb ivregress}, {helpb tsfill}

{psee}
Online: {help xttvpivmg_methods:xttvpivmg methods},
{help xttvpivmg_postestimation:xttvpivmg postestimation}
{p_end}
