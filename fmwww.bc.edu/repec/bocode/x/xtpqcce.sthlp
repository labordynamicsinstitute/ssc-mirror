{smcl}
{* *! version 1.0.0  20jun2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtpqcce postestimation" "help xtpqcce_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "xtpqcce##syntax"}{...}
{viewerjumpto "Description" "xtpqcce##description"}{...}
{viewerjumpto "Which estimator?" "xtpqcce##which"}{...}
{viewerjumpto "Options" "xtpqcce##options"}{...}
{viewerjumpto "Methods and formulas" "xtpqcce##methods"}{...}
{viewerjumpto "Practical guidance" "xtpqcce##guidance"}{...}
{viewerjumpto "Reading the output" "xtpqcce##output"}{...}
{viewerjumpto "Examples" "xtpqcce##examples"}{...}
{viewerjumpto "Stored results" "xtpqcce##results"}{...}
{viewerjumpto "References" "xtpqcce##refs"}{...}
{title:Title}

{phang}
{bf:xtpqcce} {hline 2} Heterogeneous panel quantile regression with Common
Correlated Effects: the dynamic QCCEMG estimator (Harding, Lamarche & Pesaran,
2018) and the convolution-smoothed CCEMG-CSQR estimator with two-step bias
correction (Zhang & Su, 2026)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpqcce} {it:depvar} {it:indepvars} {ifin}{cmd:,}
{opth q:uantiles(numlist)}
[{it:estimator} {it:options}]

{pstd}where {it:estimator} selects the method:{p_end}

{p2colset 9 24 26 2}{...}
{p2col:{opt qmg}}{bf:Q}uantile CCE {bf:M}ean {bf:G}roup {hline 1} {it:dynamic}
(lagged {it:depvar}), standard quantile regression. Harding, Lamarche & Pesaran
(2018). {it:This is the default.}{p_end}
{p2col:{opt csqr}}{bf:C}onvolution-{bf:S}moothed {bf:Q}uantile CCE Mean Group
(CCEMG-CSQR) {hline 1} {it:static}, smooth and convex objective, optional
two-step bias correction. Zhang & Su (2026).{p_end}
{p2colreset}{...}

{synoptset 27 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opth q:uantiles(numlist)}}quantile indices in (0,1); {bf:required}.
e.g. {cmd:quantiles(0.1(0.1)0.9)}{p_end}
{synopt:{opt l:ags(#)}}number of lags of {it:depvar} ({bf:qmg} only; default 1){p_end}
{synopt:{opt crl:ags(#)}}number of lags of the cross-sectional averages
({it:p_T}; default {bind:floor(Tbar^(1/3))}){p_end}
{synopt:{opt det:erministics(varlist)}}extra observed common factors {it:d_t}
(trend, dummies) for {bf:csqr}{p_end}
{synopt:{opt nocons:tant}}suppress the constant term{p_end}

{syntab:CSQR estimation and bias correction}
{synopt:{opt bc}}apply the {bf:two-step bias correction}
(smoothing-bias + split-panel jackknife){p_end}
{synopt:{opt c0(#)}}bandwidth tuning constant (default 0.5){p_end}
{synopt:{opt bw:idth(#)}}fix the bandwidth manually (disables the automatic rule){p_end}
{synopt:{opt jbw(#)}}number of bandwidths used in the smoothing-bias step (default 11){p_end}

{syntab:Reporting and graphics}
{synopt:{opt lr:un}}also tabulate the long-run effects beta/(1-lambda) ({bf:qmg}){p_end}
{synopt:{opt l:evel(#)}}set the confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}draw the quantile-process figure (one panel per regressor){p_end}
{synopt:{opt graphe:xport(filename)}}save that figure to {it:filename}{p_end}
{synopt:{opt not:able}}suppress the coefficient tables{p_end}
{synopt:{opt nodo:ts}}suppress the per-panel progress dots{p_end}
{synoptline}

{pstd}The data must be declared a panel with {helpb xtset} {it:panelvar timevar}.
{it:depvar} and {it:indepvars} may contain time-series operators. {cmd:xtpqcce}
is suitable for medium-to-large {it:N} and {it:T} panels with cross-sectional
dependence and heterogeneous slopes.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqcce} estimates {it:heterogeneous} panel quantile regression models in
which the units are linked by {it:unobserved common factors} (interactive fixed
effects) and therefore exhibit cross-sectional dependence. It implements the
{it:Common Correlated Effects} (CCE) idea of Pesaran (2006): the unobserved
factors are proxied by cross-sectional averages of the dependent variable and
the regressors,{p_end}

{p 12 12 2}z-bar{sub:t} = ( y-bar{sub:t} , x-bar{sub:t}' )' ,{p_end}

{pstd}
which (together with {it:p_T} of their lags) are added to a {it:unit-by-unit}
quantile regression. The unit-specific slope estimates are then averaged into a
{it:mean-group} (MG) estimator and reported for each requested quantile, so the
researcher recovers the {it:distributional} effect of each covariate {hline 1}
how its impact differs at the lower tail, the median, and the upper tail of the
conditional distribution of {it:depvar}.{p_end}

{pstd}
Two estimators are provided. Both share the same CCE augmentation and the same
mean-group inference philosophy, but they target different model classes:{p_end}

{phang2}{bf:qmg} {hline 1} the {bf:QCCEMG} estimator of Harding, Lamarche &
Pesaran (2018), for {bf:dynamic} models containing a lagged dependent variable.
Each unit is estimated by ordinary quantile regression ({helpb qreg}) of
{it:y_it} on its own lag(s), {it:x_it}, and the augmenting averages. The
parameters of interest are the persistence lambda(tau) and the short-run slopes
beta(tau); the command also reports the {bf:long-run} effects
beta(tau)/(1-lambda(tau)) and the implied {bf:half-lives}.{p_end}

{phang2}{bf:csqr} {hline 1} the {bf:CCEMG-CSQR} estimator of Zhang & Su (2026),
for {bf:static} models, specifically designed to remain valid when the time
dimension {it:T} is {it:relatively small} compared with {it:N}. Each unit is
estimated by {bf:convolution-smoothed} quantile regression (a Gaussian kernel
makes the check-function objective smooth and convex), and the mean-group
estimate can be {bf:bias-corrected} in two steps to remove the smoothing bias
and the incidental-parameter bias. This is the appropriate choice when
{it:N/T} is large (a common situation in applied panels).{p_end}

{pstd}
Results are presented in journal-style tables with significance stars and
confidence intervals, and can be visualised as {it:quantile-process} plots
(coefficient against tau with a shaded pointwise confidence band). All estimates
are saved in {cmd:e()} and the headline slopes are posted in {cmd:e(b)}/{cmd:e(V)}
so that {helpb test}, {helpb lincom} and {helpb nlcom} work.{p_end}


{marker which}{...}
{title:Which estimator should I use?}

{pstd}A short decision guide:{p_end}

{p2colset 5 30 32 2}{...}
{p2col:{bf:Question}}{bf:Use}{p_end}
{p2col:Does the model contain a lagged dependent variable / dynamics?}{cmd:qmg}{p_end}
{p2col:Static model, and {it:T} is small relative to {it:N} (say N/T > 2)?}{cmd:csqr}, {cmd:bc}{p_end}
{p2col:Static model, and {it:T} is comparable to or larger than {it:N}?}{cmd:csqr} (bias correction optional){p_end}
{p2col:You want short- {it:and} long-run distributional effects?}{cmd:qmg} with {opt lrun}{p_end}
{p2col:You need a smooth, globally optimised objective?}{cmd:csqr}{p_end}
{p2colreset}{...}

{pstd}
Both estimators require {it:T} to be reasonably large for the within-unit
quantile regressions to be well behaved; with very short {it:T} prefer
{cmd:csqr} with {opt bc}, whose theory is built for that case. As a rough rule,
aim for {it:T} of at least 20-25 and at least (1 + #regressors)(1 + p_T) + a few
usable time periods per unit after the lags are taken.{p_end}


{marker options}{...}
{title:Options}

{dlabel:Model}

{phang}{opth quantiles(numlist)} (required) lists the quantile indices, each
strictly inside (0,1). Examples: {cmd:quantiles(0.5)} (median only),
{cmd:quantiles(0.1 0.25 0.5 0.75 0.9)}, or {cmd:quantiles(0.05(0.05)0.95)} for a
full quantile process. More quantiles give a smoother picture but take longer
(especially with {opt bc}).{p_end}

{phang}{opt lags(#)} sets the number of lags of {it:depvar} entering the dynamic
model ({bf:qmg} only; default 1, the AR(1) specification of HLP 2018). The
reported persistence lambda is the {it:sum} of the AR coefficients.{p_end}

{phang}{opt crlags(#)} sets {it:p_T}, the number of lags of the cross-sectional
averages used to approximate the factors, following Chudik & Pesaran (2015). The
default floor(Tbar^(1/3)) is the standard rule. The first {it:p_T} time periods
of each panel are dropped from estimation (they have no complete proxy history).
Increasing {it:p_T} improves the factor approximation but costs degrees of
freedom; reduce it if many panels fail to estimate.{p_end}

{phang}{opt deterministics(varlist)} adds observed common deterministics
{it:d_t} (for example a linear trend or seasonal dummies) to the CCE-augmented
regression in the {bf:csqr} estimator. The constant is always included unless
{opt noconstant} is specified.{p_end}

{dlabel:CSQR estimation and bias correction}

{phang}{opt bc} requests the {bf:two-step bias correction} for {bf:csqr}, and is
the {it:headline} estimator of Zhang & Su (2026). Step 1 removes the O(h{c 94}2)
smoothing bias by combining mean-group estimates computed at {it:J} different
bandwidths (Lin & Li 2008; Cheng et al. 2018). Step 2 removes the O(1/T)
incidental-parameter bias with a {bf:split-panel jackknife} over the two halves
of the time dimension (Dhaene & Jochmans 2015). Use {opt bc} whenever {it:N/T}
is large; it is essential for correctly-sized confidence intervals there.{p_end}

{phang}{opt c0(#)} is the tuning constant c0 in the bandwidth rule (default 0.5,
the value recommended by Zhang & Su). Smaller c0 brings the estimator closer to
its non-smoothed counterpart and is generally more stable; larger c0 smooths
more.{p_end}

{phang}{opt bwidth(#)} fixes the bandwidth at a user-supplied value, overriding
the automatic rule. Mainly for sensitivity analysis.{p_end}

{phang}{opt jbw(#)} is the number of bandwidths {it:J} used in the smoothing-bias
step (default 11, with c_j = 0.5, 0.6, ..., 1.5, as in the paper).{p_end}

{dlabel:Reporting and graphics}

{phang}{opt lrun} additionally tabulates the {bf:long-run} effects
theta(tau) = beta(tau)/(1-lambda(tau)), with nonparametric mean-group inference
based on the distribution of the unit-level theta_i(tau) ({bf:qmg} only).{p_end}

{phang}{opt graph} draws one panel per regressor showing the mean-group (or
bias-corrected) coefficient across the quantiles, with a shaded pointwise
confidence band and a zero reference line. Combine with {opt graphexport()} to
save it. See {helpb xtpqcce_graph} for redrawing and styling.{p_end}

{phang}{opt level(#)}, {opt notable}, {opt nodots} behave as usual.{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}{bf:Model.} For unit {it:i} and time {it:t}, the tau-th conditional
quantile of {it:y_it} is{p_end}

{p 10 10 2}Q(tau) = a_i(tau) + lambda_i(tau) y_{i,t-1} + x_it' beta_i(tau)
+ f_t' g_i(tau),{p_end}

{pstd}where {it:f_t} is a vector of unobserved common factors with
heterogeneous loadings {it:g_i}. The slopes (lambda_i, beta_i) and the loadings
are unit-specific (full slope heterogeneity).{p_end}

{pstd}{bf:CCE augmentation.} Because {it:f_t} is unobserved, it is proxied by the
cross-sectional averages z-bar_t = (y-bar_t, x-bar_t')' and their first {it:p_T}
lags (Pesaran 2006; Chudik & Pesaran 2015). Each unit-level quantile regression
is augmented with these proxies, which absorb the common factors and the
resulting cross-sectional dependence.{p_end}

{pstd}{bf:QMG (HLP 2018).} For each unit and quantile, {helpb qreg} fits{p_end}

{p 10 10 2}y_it = a_i + lambda_i y_{i,t-1} + x_it' beta_i
+ sum_l z-bar_{t-l}' d_il + e_it .{p_end}

{pstd}The mean group is the simple average over units,
theta-hat(tau) = (1/N) sum_i theta-hat_i(tau), with theta_i = (lambda_i,
beta_i')'. Inference uses the nonparametric mean-group variance
V = (N-1){c 94}(-1) sum_i (theta_i - theta-bar)(theta_i - theta-bar)', and
the reported standard errors are sqrt(diag(V)/N). Long-run effects use the
unit-level theta_i = beta_i/(1-lambda_i) and the same nonparametric MG variance
(this is exact in spirit and avoids delta-method approximations). The half-life
is ln(0.5)/ln(|lambda|).{p_end}

{pstd}{bf:CCEMG-CSQR (Zhang & Su 2026).} Each unit is fitted by minimising the
{it:convolution-smoothed} objective
(1/T) sum_t m_{tau,h}(y_it - beta'x_it - eta'z-bar_t{c 94}a), where
m_{tau,h} = rho_tau * K_h is the check function convolved with a Gaussian kernel
of bandwidth {it:h}. The objective is smooth and convex and is solved by
Newton-Raphson. The bandwidth follows
h = c0 * min(s_u, IQR_u/1.34898) * T{c 94}(-7/24) (their eq 4.1), where s_u and
IQR_u are the spread of the fitted residuals. The mean-group estimate is
beta{c 94}MG = (1/N) sum_i beta_i. With {opt bc} the two-step correction of
their Section 3.3 is applied. Inference uses
Omega-hat = (1/N) sum_i (beta_i - beta{c 94}bc)(beta_i - beta{c 94}bc)' and
CI = S'beta{c 94}bc +/- z * sqrt(S'Omega-hat S / N) (their eq 3.11-3.12).{p_end}

{pstd}{it:Implementation note.} The Newton solver uses a generalized inverse, a
tiny data-scaled ridge, and step-damping. These are numerical safeguards only:
the smoothed objective is convex, so the solver converges to the same optimum;
they merely keep the iteration stable when the cross-sectional-average block is
near-collinear. The estimator, bandwidth, and inference are exactly as in the
papers.{p_end}


{marker guidance}{...}
{title:Practical guidance}

{phang}{bf:How many quantiles?} For a process plot use a fine grid
({cmd:quantiles(0.05(0.05)0.95)}); for a compact table use the tails and the
median ({cmd:0.1 0.25 0.5 0.75 0.9}). Avoid the extreme tails (below 0.05 or
above 0.95) unless {it:T} is large.{p_end}

{phang}{bf:Lags of the averages (p_T).} Start from the default. If panels fail
to estimate ("N_eff" < N), {it:T} is probably too short for the chosen {it:p_T};
lower {opt crlags()}. If strong dynamics remain in the residuals, raise it.{p_end}

{phang}{bf:Bias correction.} Switch {opt bc} on when {it:N/T} is large; the
uncorrected estimator can be markedly under-covered there (Zhang & Su, Table
2-4). When {it:T} is comparable to {it:N}, {opt bc} changes little but is
harmless. Note {opt bc} refits the model many times (J bandwidths x split-panel
jackknife), so it is slower.{p_end}

{phang}{bf:Bandwidth.} The default rule is robust; you rarely need {opt bwidth()}.
For a sensitivity check, vary {opt c0()} over, say, 0.3-0.8 and confirm the
estimates are stable.{p_end}

{phang}{bf:Diagnostics.} Inspect {cmd:e(b_i)} (one row per unit) to study slope
heterogeneity, and watch the reported number of successfully estimated panels.
Cross-sectional dependence and slope heterogeneity are the motivation for this
command; if both are absent, a pooled panel quantile estimator may suffice.{p_end}


{marker output}{...}
{title:Reading the output}

{pstd}{bf:Mean-group coefficient table} {hline 1} the distributional slope of
each {it:x} at each quantile, with z-statistic, p-value, CI and stars. A
coefficient that rises (falls) across tau means the covariate widens (narrows)
the conditional distribution of {it:depvar}.{p_end}

{pstd}{bf:Persistence table} ({bf:qmg}) {hline 1} lambda(tau) and its half-life.
Larger |lambda| means more persistent dynamics (slower mean reversion); the
label flags low/moderate/persistent/non-stationary behaviour.{p_end}

{pstd}{bf:Long-run table} ({bf:qmg}, with {opt lrun}) {hline 1} the cumulative
effect beta/(1-lambda) once the dynamics have played out, with nonparametric MG
inference.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Declare the panel{p_end}
{phang2}{cmd:. xtset country year}{p_end}

{pstd}Static CCEMG-CSQR across five quantiles, bias-corrected, with a plot{p_end}
{phang2}{cmd:. xtpqcce co2 gdp energy, csqr quantiles(0.1 0.25 0.5 0.75 0.9) bc graph}{p_end}

{pstd}Full quantile process, saved to file{p_end}
{phang2}{cmd:. xtpqcce co2 gdp energy, csqr quantiles(0.05(0.05)0.95) bc graph graphexport(fig1.png)}{p_end}

{pstd}Dynamic QCCEMG with short-run, persistence and long-run effects{p_end}
{phang2}{cmd:. xtpqcce y x1 x2, qmg quantiles(0.25 0.5 0.75) lags(1) lrun graph}{p_end}

{pstd}Test whether the upper-tail effect of x1 differs from the lower tail{p_end}
{phang2}{cmd:. test [q90]x1 = [q10]x1}{p_end}

{pstd}CCEMG-CSQR with a deterministic trend in d_t and more factor lags{p_end}
{phang2}{cmd:. xtpqcce y x1 x2, csqr quantiles(0.5) det(c.year) crlags(4)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpqcce} stores the following in {cmd:e()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations used{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(g_valid)}}panels successfully estimated{p_end}
{synopt:{cmd:e(Tbar)}, {cmd:e(Tmin)}}average / minimum panel length{p_end}
{synopt:{cmd:e(k)}, {cmd:e(ntau)}}# regressors / # quantiles{p_end}
{synopt:{cmd:e(crlags)}, {cmd:e(lags)}}CSA lags p_T / dynamic lags{p_end}
{synopt:{cmd:e(bw)}, {cmd:e(c0)}}bandwidth / tuning constant ({bf:csqr}){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpqcce}{p_end}
{synopt:{cmd:e(estimator)}}{cmd:qmg} or {cmd:csqr}{p_end}
{synopt:{cmd:e(biascorr)}}{cmd:twostep} if {opt bc} was used{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}, {cmd:e(tau)}}model contents{p_end}
{synopt:{cmd:e(ivar)}, {cmd:e(tvar)}}panel and time variables{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}headline slopes, one equation per quantile (qXX){p_end}
{synopt:{cmd:e(mg)}}mean-group estimates (beta; and lambda for qmg){p_end}
{synopt:{cmd:e(V_mg)}, {cmd:e(SE)}}MG covariance and standard errors{p_end}
{synopt:{cmd:e(b_i)}}per-unit beta estimates (one row per panel){p_end}
{synopt:{cmd:e(bc_mg)}}bias-corrected MG ({bf:csqr} with {opt bc}){p_end}
{synopt:{cmd:e(lr_mg)}, {cmd:e(lr_SE)}, {cmd:e(lr_V)}}long-run effects ({bf:qmg}){p_end}
{synopt:{cmd:e(lr_i)}, {cmd:e(hl_mg)}}per-unit long-run / half-lives ({bf:qmg}){p_end}


{marker refs}{...}
{title:References}

{phang}Chudik, A. and M. H. Pesaran. 2015. Common correlated effects estimation
of heterogeneous dynamic panel data models with weakly exogenous regressors.
{it:Journal of Econometrics} 188: 393-420.{p_end}

{phang}Dhaene, G. and K. Jochmans. 2015. Split-panel jackknife estimation of
fixed-effect models. {it:Review of Economic Studies} 82: 991-1030.{p_end}

{phang}Fernandes, M., E. Guerre and E. Horta. 2021. Smoothing quantile
regressions. {it:Journal of Business & Economic Statistics} 39: 338-357.{p_end}

{phang}Harding, M., C. Lamarche and M. H. Pesaran. 2018. Common Correlated
Effects estimation of heterogeneous dynamic panel quantile regression models.
USC Dornsife INET Working Paper 18-11.{p_end}

{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous
panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}

{phang}Zhang, M. and L. Su. 2026. CCE estimation of heterogeneous panel quantile
regression models with relatively small T. {it:Journal of Business & Economic
Statistics}, forthcoming. doi: 10.1080/07350015.2026.2641575.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Please cite the two methodological papers above when using {cmd:xtpqcce}.{p_end}
