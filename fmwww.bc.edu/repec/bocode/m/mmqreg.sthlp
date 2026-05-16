{smcl}
{* *! version 2.4 May 2026}{...}
{cmd:help mmqreg}

{hline}

{title:Title}

{p2colset 8 22 23 2}{...}
{p2col :{cmd:mmqreg} {hline 2}} MM-Quantile Regression with Decomposed Split-Panel Jackknife and Visualization{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:mmqreg} {depvar} {indepvars} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}

{syntab:Main}
{synopt :{opt q:uantile(numlist)}}estimate quantiles in {it:numlist}, where 0<q<100;
default is {cmd:quantile(50)}. Simultaneous estimation of multiple quantiles is supported.{p_end}

{synopt:{opt abs:orb(varlist)}}absorb fixed effects specified in {it:varlist};
requires {help hdfe} and {help ftools}.{p_end}

{synopt :{opt den:opt(string)}}specify density and bandwidth estimation method;
see {it:{help qreg##qreg_method:denmethod}} and {it:{help qreg##qreg_bwidth:bwidth}}.
Default: {cmd:bwmethod}=hsheather, {cmd:denmethod}=fitted.{p_end}

{synopt :{opt dfadj}}apply degrees-of-freedom adjustment; denominator becomes
N - k - absc, where k = total regressors and absc = absorbed coefficients.{p_end}

{synopt :{opt now:arning}}suppress warning when scale function has negative fitted values.{p_end}

{synopt :{opt nols}}suppress display of location and scale equation coefficients;
only quantile equations are reported.{p_end}

{syntab:Standard Errors}
{synopt :{opt r:obust}}report heteroskedasticity-robust (Huber-White sandwich) standard errors.{p_end}

{synopt :{opt cl:uster(varname)}}report one-way cluster-robust standard errors.{p_end}

{synopt :{opt jk:nife}}{bf:NEW (v2.4)} — apply the {bf:decomposed split-panel
jackknife} bias correction (Dhaene & Jochmans 2015 split, applied component-wise
to the MM-QR location-scale decomposition). The scale function g(.) and the
quantile location Q(tau) are each JK-corrected from half-panels, then recombined
as b_jk(tau) = b_loc + g_jk * Q_jk(tau). Inference uses the full-sample
analytical variance (MM-VCE, robust, or cluster if specified). Requires
{cmd:xtset} panel data with a time variable. Compatible with {cmd:absorb()}.{p_end}

{synoptline}
{p2colreset}{...}
{phang}{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{phang}{cmd:mmqreg} supports {cmd:aweight}, {cmd:pweight}, {cmd:iweight}, {cmd:fweight}.{p_end}


{marker syntax_examples}{...}
{title:Syntax examples}

{pstd}Median MM-QR, no fixed effects:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2 x3}{p_end}

{pstd}Multiple quantiles (joint covariance):{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2 x3}{cmd:, q(10 25 50 75 90)}{p_end}

{pstd}Quantile range via numlist shorthand:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2 x3}{cmd:, q(10(20)90)}{p_end}

{pstd}Panel fixed effects (requires {help hdfe}/{help ftools}):{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2 x3}{cmd:, absorb(}{it:id}{cmd:) q(50)}{p_end}

{pstd}Two-way absorbed FE:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2}{cmd:, absorb(}{it:id year}{cmd:) q(25 50 75)}{p_end}

{pstd}Robust / clustered SE:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2}{cmd:, robust q(50)}{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2}{cmd:, cluster(}{it:id}{cmd:) q(25 50 75)}{p_end}

{pstd}Decomposed split-panel jackknife ({bf:v2.4}):{p_end}
{phang2}{cmd:. xtset} {it:id t}{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2}{cmd:, absorb(}{it:id}{cmd:) q(50) jknife}{p_end}

{pstd}JK + clustered SE:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2}{cmd:, absorb(}{it:id}{cmd:) cluster(}{it:id}{cmd:) q(10 50 90) jknife}{p_end}

{pstd}JK + bootstrap variance (MM-QR-JK style):{p_end}
{phang2}{cmd:. bs, cluster(}{it:id}{cmd:) rep(200): mmqreg} {it:y x1 x2}{cmd:, absorb(}{it:id}{cmd:) q(50) jknife}{p_end}

{pstd}Weights:{p_end}
{phang2}{cmd:. mmqreg} {it:y x1 x2} {cmd:[pw=}{it:wt}{cmd:], q(25 50 75)}{p_end}

{pstd}Replay last results:{p_end}
{phang2}{cmd:. mmqreg}{p_end}


{title:Visualization — mmqregplot}

{p 8 16 2}
{cmd:mmqregplot} [{varlist}] [{cmd:,} {it:plot_options}]

{pstd}Must be run immediately after {cmd:mmqreg}. Re-estimates the model across all
requested quantiles and plots the coefficient path with a shaded confidence band.{p_end}

{synoptset 28 tabbed}{...}
{synopthdr :plot_options}
{synoptline}

{synopt :{opt q:uantile(numlist)}}quantile range for the plot; default is {cmd:10(5)90}.{p_end}
{synopt :{opt ols}}overlay OLS reference line and confidence band.{p_end}
{synopt :{opt olsopt(string)}}options passed to {cmd:regress} for the OLS overlay.{p_end}
{synopt :{opt ra:opt(string)}}graph options for the confidence-band {cmd:rarea}.{p_end}
{synopt :{opt ln:opt(string)}}graph options for the coefficient line.{p_end}
{synopt :{opt two:opt(string)}}twoway options (applied to every panel).{p_end}
{synopt :{opt grc:opt(string)}}options passed to {cmd:graph combine}.{p_end}
{synopt :{opt cons}}include constant in the plot.{p_end}
{synopt :{opt label}}use variable labels as panel titles.{p_end}
{synopt :{opt mt:itles(string)}}override panel titles (space-separated quoted strings).{p_end}
{synopt :{opt level(#)}}confidence level; default 95.{p_end}

{synoptline}


{title:Description}

{pstd}
{cmd:mmqreg} estimates quantile regressions using the Method of Moments approach
described in Machado and Santos Silva (2019). The estimator is based on a
location-scale model:

{pmore}
y = x'b + (x'g) * U

{pstd}
where {bf:b} captures location effects, {bf:g} captures scale effects, and U
is the standardized residual whose conditional quantiles Q(tau) recover the
conditional quantile function of y given x:

{pmore}
beta(tau) = b + g * Q(tau)


{marker whatsnew24}{...}
{title:What's new in v2.4 (Decomposed Split-Panel Jackknife)}

{pstd}
v2.4 adds the {cmd:jknife} option, integrating the {bf:MM-QR-JK} half-panel
jackknife bias correction into {cmd:mmqreg}. In short-T panels with fixed
effects, the MM-QR scale function and quantile-location estimators inherit the
incidental-parameters bias of within-transformed estimators. The decomposed JK
removes the leading-order bias from these two components separately rather than
from the final beta(tau).{p_end}

{pstd}
{bf:Procedure.} Given a panel {cmd:xtset} with a time variable t, the routine:{p_end}

{phang}1. Estimates the full-sample MM-QR, retrieving location b, scale g,
quantile-location Q(tau), and sample size N.{p_end}

{phang}2. Splits the panel into a "low" half (s=0, even t) and a "high" half
(s=1, odd t) via s = 2*(t/2 - int(t/2)).{p_end}

{phang}3. Re-estimates MM-QR on each half, yielding (g0, Q0, N0) and (g1, Q1, N1).{p_end}

{phang}4. Constructs the JK-corrected components:{p_end}

{pmore}g_jk    = 2*g     - (N0/N)*g0     - (N1/N)*g1{p_end}
{pmore}Q_jk(t) = 2*Q(t)  - (N0/N)*Q0(t)  - (N1/N)*Q1(t){p_end}

{phang}5. Recombines them into bias-corrected quantile coefficients:{p_end}

{pmore}beta_jk(tau) = b_loc + g_jk * Q_jk(tau){p_end}

{pstd}
The location vector {bf:b_loc} is left at its full-sample value because the
within/OLS location estimator is unbiased for linear FE models — only the
scale and quantile-location components carry IP bias. Inference uses the
{bf:full-sample analytical variance} (MM-VCE, optionally {cmd:robust} or
{cmd:cluster}). Wrap the call in {cmd:bs:} for a bootstrap variance.{p_end}

{pstd}
{bf:When to use it.}{p_end}
{phang}- Short panels (small T, especially T < 30) with fixed effects.{p_end}
{phang}- When you want bias-corrected point estimates without resorting to bootstrap.{p_end}
{phang}- Compatible with single quantile or simultaneous estimation of multiple quantiles.{p_end}

{pstd}
{bf:Compared to the v2.4 legacy direct-b SPJ (removed):} the decomposed approach
corrects the {it:components} of the MM-QR model, which is preferable when only
the IP-affected pieces (scale, quantile location) need correction — the OLS
location is left untouched, in line with linear-FE theory.{p_end}

{pstd}
{bf:Additional v2.4 deliverables.}{p_end}

{phang}1. {bf:mmqregplot} — companion visualization command that plots the
coefficient path across the quantile distribution with shaded confidence bands.
Supports multi-panel layouts, OLS overlay, variable labels, and full
{cmd:twoway} customization.{p_end}

{phang}2. {bf:Enhanced display header} — reports sample size, clusters (if
applicable), absorbed FEs, SE type (incl. "Split-Panel Jackknife"), and the
quantile(s) estimated, clearly formatted.{p_end}

{phang}3. {bf:bls/vls returned in FE path} — {cmd:e(bls)} and {cmd:e(vls)} are
now always returned (including with {cmd:absorb}), exposing the location and
scale blocks for post-estimation use.{p_end}

{phang}4. {bf:New e() returns under jknife} — see {it:Stored Results} below
({cmd:e(qval_full)}, {cmd:e(N_h0)}, {cmd:e(N_h1)}, {cmd:e(jk_formula)}).{p_end}


{title:Comparison with xtqreg}

{pstd}
Compared with {help xtqreg}, {cmd:mmqreg} additionally:{p_end}
{phang}1. Estimates the model without fixed effects (plain OLS location-scale).{p_end}
{phang}2. Absorbs multiple fixed effects via {cmd:hdfe}/{cmd:ftools}.{p_end}
{phang}3. Estimates multiple quantiles jointly with correct joint covariance.{p_end}
{phang}4. Provides analytical (MM-VCE), robust, clustered, and decomposed-JK estimators.{p_end}


{title:Stored Results}

{pstd}{cmd:mmqreg} stores the following in {cmd:e()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (if cluster SE){p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom (if {cmd:dfadj}){p_end}
{synopt:{cmd:e(N_h0)}}observations in low (s=0) half-panel ({cmd:jknife}){p_end}
{synopt:{cmd:e(N_h1)}}observations in high (s=1) half-panel ({cmd:jknife}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mmqreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(vce)}}vcetype: {cmd:mmvce}, {cmd:cluster}, or {cmd:jk}{p_end}
{synopt:{cmd:e(jk)}}"Split-Panel Jackknife (decomposed)" when {cmd:jknife} was used{p_end}
{synopt:{cmd:e(jk_formula)}}"b_loc + g_jk * Q_jk(tau)" ({cmd:jknife}){p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust} if robust or cluster SE{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(fevlist)}}list of absorbed fixed effects{p_end}
{synopt:{cmd:e(denmethod)}}density method used{p_end}
{synopt:{cmd:e(bwmethod)}}bandwidth method used{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (location, scale, quantile equations){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(qth)}}target quantile values used (in [0,1]){p_end}
{synopt:{cmd:e(qval)}}quantile of standardized residuals; JK-corrected Q_jk under {cmd:jknife}{p_end}
{synopt:{cmd:e(qval_full)}}uncorrected full-sample Q(tau) ({cmd:jknife} only){p_end}
{synopt:{cmd:e(fden)}}density at quantile (from {cmd:qreg}){p_end}
{synopt:{cmd:e(bls)}}{b_loc | g | qval}; under {cmd:jknife}, {b_loc | g_jk | Q_jk}{p_end}
{synopt:{cmd:e(vls)}}variance of location+scale block{p_end}


{title:Examples}

    {hline}
{pstd}{bf:Setup} — load panel data and (optionally) keep a balanced subset for JK demos{p_end}
{phang2}{stata webuse nlswork, clear}{p_end}
{phang2}{stata xtset idcode year}{p_end}
{phang2}{stata by idcode: egen c = count(idcode)}{p_end}
{phang2}{stata keep if c >= 10}{p_end}

{pstd}{bf:Install dependencies} (one-off; required for {cmd:absorb()}){p_end}
{phang2}{stata ssc install ftools}{p_end}
{phang2}{stata ssc install hdfe}{p_end}

    {hline}
{bf:Section 1 — Basic MM-QR (no fixed effects)}
    {hline}

{pstd}{bf:1a. Median regression}{p_end}
{phang2}{stata mmqreg ln_w age ttl_exp tenure not_smsa south}{p_end}

{pstd}{bf:1b. Multiple quantiles simultaneously} (joint covariance){p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, q(10 25 50 75 90)"}{p_end}

{pstd}{bf:1c. Quantile range via numlist shorthand}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, q(10(20)90)"}{p_end}

{pstd}{bf:1d. Suppress location/scale equations} (only quantile equations reported){p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, q(25 50 75) nols"}{p_end}

{pstd}{bf:1e. Replay last estimation}{p_end}
{phang2}{stata mmqreg}{p_end}

    {hline}
{bf:Section 2 — MM-QR with Fixed Effects}
    {hline}

{pstd}{bf:2a. One-way FE} (absorb individual effect){p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50)"}{p_end}

{pstd}{bf:2b. Two-way FE} (individual + time){p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode year) q(25 50 75)"}{p_end}

{pstd}{bf:2c. Clustered SE with FE}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) cluster(idcode) q(25 50 75)"}{p_end}

{pstd}{bf:2d. Robust (Huber-White) SE}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, robust q(50)"}{p_end}

{pstd}{bf:2e. Degrees-of-freedom adjustment}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) dfadj q(50)"}{p_end}

    {hline}
{bf:Section 3 — Decomposed Split-Panel Jackknife (v2.4 NEW)}
    {hline}
{pstd}The {cmd:jknife} option requires {cmd:xtset} panel data (panel + time
variable). The routine fits MM-QR on the full sample plus the two half-panels
(even t and odd t), and applies the component-wise correction
{it:b_jk(tau) = b_loc + g_jk * Q_jk(tau)}.{p_end}

{pstd}{bf:3a. JK without FE}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, q(50) jknife"}{p_end}

{pstd}{bf:3b. JK with fixed effects} (typical use case){p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50) jknife"}{p_end}

{pstd}{bf:3c. JK + clustered SE}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) cluster(idcode) q(25 50 75) jknife"}{p_end}

{pstd}{bf:3d. JK + bootstrap variance} (mirrors MM-QR-JK reference do-file){p_end}
{phang2}{stata "bs, cluster(idcode) rep(200): mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50) jknife"}{p_end}

{pstd}{bf:3e. JK at multiple quantiles}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(10 25 50 75 90) jknife"}{p_end}

{pstd}{bf:3f. Compare analytical vs JK at the median} (using {help estout:esttab}){p_end}
{phang2}{stata "qui mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50)"}{p_end}
{phang2}{stata "estimates store mmq_analytic"}{p_end}
{phang2}{stata "qui mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50) jknife"}{p_end}
{phang2}{stata "estimates store mmq_jk"}{p_end}
{phang2}{stata `"esttab mmq_analytic mmq_jk, mtitles("Analytical" "JK") keep(*:tenure *:age *:ttl_exp)"'}{p_end}

{pstd}{bf:3g. Inspect JK internals}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50) jknife"}{p_end}
{phang2}{stata "matrix list e(qval)"}{p_end}
{phang2}{stata "matrix list e(qval_full)"}{p_end}
{phang2}{stata "matrix list e(bls)"}{p_end}
{phang2}{stata "display e(N_h0) " " e(N_h1)"}{p_end}

    {hline}
{bf:Section 4 — Manual JK replication}
    {hline}
{pstd}For transparency, this block reproduces the JK decomposition step-by-step
using only the {bf:full}-sample and {bf:half}-sample MM-QR calls. The result
matches {cmd:e(b)} from {cmd:jknife}.{p_end}

{phang2}{stata "gen byte s = 2*((year/2) - int(year/2))"}{p_end}
{phang2}{stata "qui mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50)"}{p_end}
{phang2}{stata "matrix bls_full = e(bls)"}{p_end}
{phang2}{stata "matrix Q_full   = e(qval)"}{p_end}
{phang2}{stata "scalar N        = e(N)"}{p_end}
{phang2}{stata "qui mmqreg ln_w age ttl_exp tenure not_smsa south if s==0, absorb(idcode) q(50)"}{p_end}
{phang2}{stata "matrix bls_h0 = e(bls)"}{p_end}
{phang2}{stata "matrix Q_h0   = e(qval)"}{p_end}
{phang2}{stata "scalar N0     = e(N)"}{p_end}
{phang2}{stata "qui mmqreg ln_w age ttl_exp tenure not_smsa south if s==1, absorb(idcode) q(50)"}{p_end}
{phang2}{stata "matrix bls_h1 = e(bls)"}{p_end}
{phang2}{stata "matrix Q_h1   = e(qval)"}{p_end}
{phang2}{stata "scalar N1     = e(N)"}{p_end}

    {hline}
{bf:Section 5 — Visualization (mmqregplot)}
    {hline}

{pstd}{bf:5a. Default coefficient paths}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south"}{p_end}
{phang2}{stata "mmqregplot, quantile(10(5)90)"}{p_end}

{pstd}{bf:5b. Subset of variables with OLS overlay}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, quantile(10(5)90) ols"}{p_end}

{pstd}{bf:5c. Variable labels as panel titles}{p_end}
{phang2}{stata "mmqregplot, quantile(10 25 50 75 90) label"}{p_end}

{pstd}{bf:5d. Custom styling}{p_end}
{phang2}{stata `"mmqregplot age ttl_exp tenure, raopt(color(maroon%20) lwidth(none)) lnopt(lcolor(maroon) lwidth(thick))"'}{p_end}

{pstd}{bf:5e. Plot after JK estimation}{p_end}
{phang2}{stata "mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(10(10)90) jknife"}{p_end}
{phang2}{stata "mmqregplot age ttl_exp tenure, ols label"}{p_end}

    {hline}


{title:Remarks}

{pstd}
The {cmd:jknife} option implements the {bf:decomposed split-panel jackknife}.
It splits the time series into "low" (even t) and "high" (odd t) periods
via s = 2*(t/2 - int(t/2)), re-estimates MM-QR on each half, and applies
the bias correction to the scale and quantile-location components
separately:{p_end}

{pmore}g_jk    = 2*g     - (N0/N)*g0     - (N1/N)*g1{p_end}
{pmore}Q_jk(t) = 2*Q(t)  - (N0/N)*Q0(t)  - (N1/N)*Q1(t){p_end}
{pmore}beta_jk(tau) = b_loc + g_jk * Q_jk(tau){p_end}

{pstd}
Inference is based on the full-sample analytical variance (MM-VCE, optionally
{cmd:robust} or {cmd:cluster}). For a bootstrap variance, prefix the command
with {cmd:bs:} (see Example 7).{p_end}

{pstd}
The {cmd:mmqregplot} command re-estimates the model at each quantile requested
and constructs coefficient-path plots using Stata's {cmd:twoway} engine.
All plots show a shaded confidence band (95% by default) and a bold coefficient
line. A zero reference line is drawn. When multiple variables are plotted,
sub-panels are combined using {cmd:graph combine}.{p_end}

{pstd}I thank J.M.C. Santos Silva for clarifications on the estimation methodology.
All errors are my own.{p_end}


{title:References}

{phang}Dhaene, G. and Jochmans, K. (2015),
{browse "https://doi.org/10.1093/restud/rdv007":Split-panel jackknife estimation of fixed-effect models},
{it:Review of Economic Studies}, 82(3), pp. 991-1030.{p_end}

{phang}Machado, J.A.F. and Santos Silva, J.M.C. (2019),
{browse "https://doi.org/10.1016/j.jeconom.2019.04.009":Quantiles via moments},
{it:Journal of Econometrics}, 213(1), pp. 145-173.{p_end}

{phang}Rios-Avila, Fernando (2020),
Extending quantile regressions via method of moments using multiple fixed effects. MIMEO.{p_end}


{title:Authors}

{pstd}
{bf:Fernando Rios-Avila} (original author, v1.0–v2.3){break}
Levy Economics Institute, Annandale-on-Hudson, NY{break}
friosa@gmail.com{p_end}

{pstd}
{bf:Dr Merwan Roudane} (contributor, v2.4 — Decomposed Jackknife & Plot){break}
merwanroudane920@gmail.com{p_end}


{title:Also see}

{psee}
{help xtqreg}, {help qreg}, {help hdfe}, {help ftools}, {help mmqregplot}
