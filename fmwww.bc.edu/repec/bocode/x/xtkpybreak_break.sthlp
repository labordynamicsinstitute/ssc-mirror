{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "xtkpybreak" "help xtkpybreak"}{...}
{vieweralsosee "xtkpybreak cce" "help xtkpybreak_cce"}{...}
{vieweralsosee "xtkpybreak postestimation" "help xtkpybreak_postestimation"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{viewerjumpto "Syntax" "xtkpybreak_break##syntax"}{...}
{viewerjumpto "Description" "xtkpybreak_break##description"}{...}
{viewerjumpto "Options" "xtkpybreak_break##options"}{...}
{viewerjumpto "Stored results" "xtkpybreak_break##results"}{...}
{viewerjumpto "Remarks" "xtkpybreak_break##remarks"}{...}
{viewerjumpto "Examples" "xtkpybreak_break##examples"}{...}
{viewerjumpto "Author" "xtkpybreak_break##author"}{...}
{title:Title}

{phang}
{bf:xtkpybreak break} {hline 2} Multiple structural breaks in slopes and
error-factor loadings of non-stationary heterogeneous panels
(Baltagi, Feng & Wang 2025)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtkpybreak break} {depvar} {indepvars} {ifin}
{cmd:,} {opt nbr:eaks(#)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt nbr:eaks(#)}}number of structural breaks {it:m} to estimate
(required, >= 1){p_end}
{synopt :{opt load:ings}}also allow breaks in the error-factor loadings
(BFW model 5); the default is breaks in slopes only (model 4){p_end}
{synopt :{opt proxy(x|yx)}}factor proxy: cross-section averages of the
regressors only ({bf:x}, the BFW default) or of ({it:depvar},{it:indepvars})
({bf:yx}){p_end}
{synopt :{opt trim(#)}}trimming fraction; breaks are searched in
[{it:#}T, (1-{it:#})T]; default {cmd:trim(0.10)} as in BFW{p_end}
{synopt :{opt nons:tationary}}label the regressors as I(1) after the CCE
transform (BFW Case 2, T-consistent slopes); affects only the reported theory,
not the point estimates{p_end}
{synopt :{opt nocon:stant}}proxy f(t) by the cross-section averages alone, with
no intercept in the proxy block (strict BFW eq. 9){p_end}
{synopt :{opt hac(#)}}Bartlett (Newey-West) window for the {it:individual}-slope
standard errors (BFW Prop. 1); default is the automatic
floor(4(T/100){c 94}(2/9)){p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{syntab:Graphs}
{synopt :{opt breakplot}}plot the cross-section average of {it:depvar} over time
with the estimated break dates marked{p_end}
{synopt :{opt coefe:volution}}plot the regime-by-regime mean-group slope of the
first regressor as a step function with confidence band{p_end}
{synopt :{opt name(stub)}}name stub for the saved graphs (default {bf:xtkpb}){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtkpybreak break} estimates {it:m} unknown structural break points and the
regime-specific slopes in a non-stationary heterogeneous panel with an
unobserved multifactor error structure, following Baltagi, Feng & Wang (2025).
Building on Kapetanios, Pesaran & Yamagata (2011), the unobserved I(1) factors
are proxied by cross-section averages; breaks in slopes and (optionally) in
error-factor loadings then reduce to breaks in a linear panel regression, which
are estimated by least squares using the Bai & Perron (1998, 2003)
dynamic-programming algorithm.

{pstd}
The break {it:dates} are found by minimizing the panel sum of squared residuals
of the {it:unrestricted} regression, in which the augmented regressor
z(it) = (x(it), proxy(t)) is fully interacted with the regimes, over all
admissible {it:m}-partitions (BFW eqs 11-13); the global optimum is obtained by
dynamic programming, not a heuristic. As N grows, the estimated break dates
converge to the truth (BFW Theorems 1-2). Given the breaks, the regime slopes
are computed by the partitioned CCE regression b(i) = [X(i)(K0)' M X(i)(K0)]^-1
X(i)(K0)' M Y(i) (BFW eqs 14-15) and averaged across panels to give a
{bf:mean-group} estimate per regime, whose standard error comes from the
cross-panel dispersion (BFW Proposition 2). A pooled estimate is also stored.

{pstd}
{bf:Two break specifications.} Because the break dates come from the unrestricted
model, the {opt loadings} option does {it:not} change the break dates {hline 1} it
changes only how the regime slopes are then estimated:

{phang2}o {bf:model 4} (default) {hline 1} the error-factor loadings are held
constant; the proxy projection M is global (BFW eq. 14). This is the correctly
specified, more efficient estimator when only the slopes break.{p_end}

{phang2}o {bf:model 5} ({opt loadings}) {hline 1} the loadings may break together
with the slopes; the proxy projection M is regime-specific (BFW eq. 15). Use when
the error-factor variance may also shift.{p_end}

{pstd}
{bf:Requirements.} The data must be {helpb xtset} and {bf:balanced}.
Time-series operators are allowed in {it:indepvars}. Because the unrestricted
break search fits z(it) = (x(it), proxy(t)) in every regime, with {it:m} breaks
and trimming {it:#} at least (m+1) regimes each of length >= max({it:#}T, k+p+1)
must fit in T, where p is the width of the proxy block (1 constant + the
regressor averages, plus the {it:depvar} average under {opt proxy(yx)}); other-
wise the command stops and asks you to reduce {opt nbreaks()} or {opt trim()}.

{marker options}{...}
{title:Options}

{phang}
{opt nbreaks(#)} sets the number of break points {it:m} (required). The sample
is split into {it:m}+1 regimes. When {opt loadings} is not specified, all breaks
are in the slopes; when it is, the breaks are a joint set of slope and loading
breaks (BFW pool them, eq. 11).

{phang}
{opt loadings} switches from model 4 (slope breaks) to model 5 (slope {it:and}
loading breaks). See {it:Description}.

{phang}
{opt proxy(x|yx)} selects the cross-section averages used as the factor proxy;
{bf:x} (regressors only) is the BFW default, {bf:yx} adds the average of the
dependent variable (Pesaran/KPY style).

{phang}
{opt trim(#)} sets the minimum regime length as a fraction of T. BFW use 0.10
(search over 0.1T ... 0.9T). Must lie in (0, 0.5).

{phang}
{opt nonstationary} declares the idiosyncratic regressor component v(it) to be
I(1) (BFW Case 2). In that case y(it) and x(it) cointegrate within each regime
and the individual slopes are T-consistent (super-consistent), and the relative
rate restriction is not needed. This option changes only the theory note printed
and stored in {bf:e(regressors)}; the point estimates and break dates are
computed identically.

{phang}
{opt noconstant} proxies the unobserved factors by the cross-section averages
{it:x-bar(t)} (and {it:y-bar(t)} under {opt proxy(yx)}) with no separate
intercept, matching BFW eq. (9) exactly. By default a constant (the KPY
deterministic {it:D} term) is included in the proxy block; it is either held
constant (model 4) or allowed to break with the loadings (model 5). Note the
minimum regime length falls by one when {opt noconstant} is used.

{phang}
{opt hac(#)} sets the Bartlett/Newey-West truncation window used for the
{it:individual}-panel slope standard errors (BFW Proposition 1, eqs 17-18). The
default (a negative value) uses the automatic bandwidth
floor(4(T/100){c 94}(2/9)). These per-panel HAC standard errors are stored in
{bf:e(se_i)}; they are distinct from the mean-group standard errors shown in the
table, which come from the cross-panel dispersion (Proposition 2) and need no
kernel. The window actually used is stored in {bf:e(hac)}.

{phang}
{opt level(#)} sets the confidence level for the reported intervals and the
{opt coefevolution} band.

{phang}
{opt breakplot} plots the cross-section average of {it:depvar} against time with
vertical dashed lines at the estimated break dates.

{phang}
{opt coefevolution} plots the mean-group slope of the {it:first} regressor as a
step function across regimes, with a shaded {it:level}% confidence band and
vertical lines at the break dates {hline 1} the standard "structural change"
picture used in applied panels.

{phang}
{opt name(stub)} sets the stub for saved graph names: {it:stub}{bf:_break} and
{it:stub}{bf:_evo}.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtkpybreak break} stores the following in {cmd:e()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels (N){p_end}
{synopt:{cmd:e(Tbar)}}time periods per panel (T){p_end}
{synopt:{cmd:e(k)}}number of regressors{p_end}
{synopt:{cmd:e(nbreaks)}}number of breaks {it:m}{p_end}
{synopt:{cmd:e(ssr)}}minimized total sum of squared residuals{p_end}
{synopt:{cmd:e(trim)}}trimming fraction{p_end}
{synopt:{cmd:e(hac)}}Newey-West window used for the individual s.e.{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtkpybreak}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:break}{p_end}
{synopt:{cmd:e(model)}}break specification (model 4 / model 5){p_end}
{synopt:{cmd:e(regressors)}}Case 1 (I(0)) or Case 2 (I(1)){p_end}
{synopt:{cmd:e(proxy)}}{cmd:x} or {cmd:yx}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}stacked regime mean-group slopes (equations
{bf:r1}..{bf:r(m+1)}) and their variance{p_end}
{synopt:{cmd:e(breakdates)}}m x 1 vector of estimated break dates (time values){p_end}
{synopt:{cmd:e(breakobs)}}m x 1 vector of break positions (observation index){p_end}
{synopt:{cmd:e(b_regime)}, {cmd:e(se_regime)}}(m+1) x k regime mean-group slopes{p_end}
{synopt:{cmd:e(bp_regime)}, {cmd:e(sep_regime)}}(m+1) x k regime pooled slopes{p_end}
{synopt:{cmd:e(b_i)}}(k(m+1)) x N matrix of per-panel regime slopes{p_end}
{synopt:{cmd:e(se_i)}}(k(m+1)) x N matrix of per-panel Newey-West s.e. (Prop. 1){p_end}

{marker remarks}{...}
{title:Remarks and interpretation}

{pstd}
{bf:Reading the output.} The header reports N, T, the break specification
(model 4 vs 5), the regressor case (I(0) vs I(1)), and the factor proxy. Next
come the estimated break dates (in {it:time} units, e.g. calendar years) and the
minimized SSR. The main block gives, for each of the {it:m}+1 regimes, the
mean-group slope of every regressor with its cross-panel standard error, z and
p-value, and significance stars.

{pstd}
{bf:What each estimator is for.}

{phang2}o {bf:Mean-group} (shown): the average of the N per-panel slopes in each
regime, with a standard error from their dispersion (BFW Prop. 2). This is the
headline estimator for the {it:population} slope in each regime.{p_end}

{phang2}o {bf:Pooled} ({cmd:e(bp_regime)}): a precision-weighted average (BFW
footnote 13); more efficient when the slopes are homogeneous.{p_end}

{phang2}o {bf:Individual} ({cmd:e(b_i)}/{cmd:e(se_i)}): each panel's own regime
slopes with Newey-West HAC standard errors (BFW Prop. 1). Use these when a single
unit is of interest.{p_end}

{pstd}
{bf:Choosing m.} {cmd:nbreaks()} is the total number of breaks. The command does
{it:not} test how many breaks exist; select {it:m} on substantive grounds, an
information criterion, or an external test (e.g. Bai-Perron sup-F, or the common-
break CUSUM test of Jiang and Kurozumi 2023). Over-stating {it:m} inflates the
per-regime parameter count and the minimum regime length required.

{pstd}
{bf:model 4 vs model 5.} The break {it:dates} are identical either way (both use
the unrestricted fully-interacted DP). Choose the {it:slope} estimator by whether
you believe the error-factor loadings are stable ({bf:model 4}, default, more
efficient) or may themselves shift ({bf:model 5}, {opt loadings}). When only the
slopes truly break, model 4 is the correctly specified and tighter estimator.

{pstd}
{bf:Consistency.} Break dates are consistently estimated as (N,T) grow, and the
probability of picking the true dates rises sharply with N (BFW Theorems 1-2).
Nonstationary regressors make breaks {it:easier} to date; I(1) idiosyncratic
errors (spurious regression) make them harder.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}One break in the slopes; inspect the estimated date{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1)}{p_end}
{phang2}{cmd:. matrix list e(breakdates)}{p_end}

{pstd}Same, with the two journal-style graphs{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) breakplot coefevolution}{p_end}

{pstd}Did the {cmd:mvalue} slope change across the break?{p_end}
{phang2}{cmd:. test [r1]mvalue = [r2]mvalue}{p_end}

{pstd}Two breaks, allowing the loadings to break too, with 15% trimming{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(2) loadings trim(0.15)}{p_end}

{pstd}Individual-panel slopes with Newey-West s.e. (window 2){p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) hac(2)}{p_end}
{phang2}{cmd:. matrix list e(b_i)}{p_end}
{phang2}{cmd:. matrix list e(se_i)}{p_end}

{pstd}Strict BFW eq. (9) proxy (no intercept); (y-bar, x-bar) proxy{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) noconstant}{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) proxy(yx)}{p_end}

{pstd}Case 2 (I(1) regressors, T-consistent slopes) labelling{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) nonstationary}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
