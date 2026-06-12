{smcl}
{* 10jun2026}{...}
{vieweralsosee "xtdynestimb dd" "help xtdynestimb_dd"}{...}
{vieweralsosee "xtdynestimb csdgmm" "help xtdynestimb_csdgmm"}{...}
{vieweralsosee "xtdynestimb ablasso" "help xtdynestimb_ablasso"}{...}
{vieweralsosee "xtdynestimb postestimation" "help xtdynestimb_postestimation"}{...}
{vieweralsosee "xtdyntest" "help xtdyntest"}{...}
{vieweralsosee "xtabond2" "help xtabond2"}{...}
{vieweralsosee "xtdpdgmm" "help xtdpdgmm"}{...}
{viewerjumpto "Syntax" "xtdynestimb##syntax"}{...}
{viewerjumpto "Description" "xtdynestimb##description"}{...}
{viewerjumpto "Subcommands" "xtdynestimb##subcommands"}{...}
{viewerjumpto "Options" "xtdynestimb##options"}{...}
{viewerjumpto "Visualization" "xtdynestimb##graph"}{...}
{viewerjumpto "Stored results" "xtdynestimb##results"}{...}
{viewerjumpto "Examples" "xtdynestimb##examples"}{...}
{viewerjumpto "References" "xtdynestimb##references"}{...}
{viewerjumpto "Author" "xtdynestimb##author"}{...}
{title:Title}

{phang}
{bf:xtdynestimb} {hline 2} Dynamic linear panel-data estimators robust to
structural breaks, long-{it:T} overidentification, and error cross-sectional
dependence

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtdynestimb} {it:subcommand} {it:depvar} [{it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{p 4 4 2}
where {it:subcommand} is one of:

{synoptset 18 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb xtdynestimb_dd:dd}}Difference / System / {it:Double-D} GMM,
robust to structural breaks (Chowdhury & Russell 2017){p_end}
{synopt:{helpb xtdynestimb_csdgmm:csdgmm}}CSD-robust GMM via time-demeaning +
partial instruments (Sarafidis 2009){p_end}
{synopt:{helpb xtdynestimb_ablasso:ablasso}}Arellano-Bond LASSO for long-{it:T}
panels, with cross-fitting (Chernozhukov et al. 2024){p_end}
{synopt:{helpb xtdynestimb##dabss:dabss}}Debiased Arellano-Bond via split-panel
jackknife (Chen, Chernozhukov & Fernandez-Val 2019){p_end}
{synopt:{helpb xtdynestimb##breaks:breaks}}Bai-Perron structural-break / regime
detection (Chowdhury-Russell Table A1 step){p_end}
{synopt:{helpb xtdynestimb##table:table}}Journal-style comparison table across
estimators (Chowdhury-Russell Table 7 layout){p_end}
{synopt:{helpb xtdynestimb##graph:graph}}Coefficient plot after estimation{p_end}
{synoptline}

{p 4 4 2}
{it:depvar} is the dependent variable. {it:indepvars} (optional) are treated as
{bf:strictly exogenous} additional regressors. The lagged dependent variable is
generated automatically from {cmd:lags()}; do {it:not} include it in
{it:indepvars}. The data must be {helpb xtset}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdynestimb} estimates the dynamic linear panel-data model

{p 8 8 2}
{it:y_it} = {it:a_1} {it:y_i,t-1} + ... + {it:a_p} {it:y_i,t-p} +
{it:x_it' b} + {it:eta_i} [+ {it:f_t}] + {it:v_it}

{pstd}
with three modern estimators that each address a different failure of the
textbook Arellano-Bond / Blundell-Bond GMM estimator:

{phang2}
o {bf:Structural breaks.} Mean shifts in the fixed effects invalidate the
standard difference and system moment conditions. {helpb xtdynestimb_dd:dd}
adds the break-robust {it:double-difference} moment conditions of Chowdhury &
Russell (2017) ({bf:both} the instruments {bf:and} the equation are in
differences) and offers five nested estimators.{p_end}

{phang2}
o {bf:Error cross-sectional dependence.} Common factors make the lagged-level
instruments invalid. {helpb xtdynestimb_csdgmm:csdgmm} removes the common
factors by cross-sectional (time) demeaning and, optionally, restricts the
instrument set to the regressors only (Sarafidis 2009).{p_end}

{phang2}
o {bf:Long-{it:T} overidentification bias.} When {it:T} is large the number of
AB moment conditions grows like {it:T}{c 94}2, biasing the estimator.
{helpb xtdynestimb_ablasso:ablasso} uses period-by-period LASSO to keep only the
most informative instruments and cross-fitting to remove the over-fitting bias
(Chernozhukov, Fernandez-Val, Huang & Wang 2024).{p_end}

{pstd}
All three are {bf:estimation} commands: they post {cmd:e(b)} and {cmd:e(V)}, so
you can use {helpb test}, {helpb lincom}, {helpb nlcom} (e.g. for long-run
effects), {helpb estimates}, {helpb predict} and the companion specification
tests in {helpb xtdyntest}. The engine is self-contained Mata; no other package
is required.

{marker subcommands}{...}
{title:Subcommands (click for full help)}

{phang}{helpb xtdynestimb_dd:xtdynestimb dd} {hline 2} Difference, System and
Double-D GMM under structural breaks; {cmd:variant()} selects
{cmd:difference}, {cmd:system}, {cmd:ddback}, {cmd:ddforward} or {cmd:full};
{cmd:compare} estimates all five side by side.

{phang}{helpb xtdynestimb_csdgmm:xtdynestimb csdgmm} {hline 2} CSD-robust GMM;
time-demeaning on by default; {cmd:partial} uses regressor-only instruments.

{phang}{helpb xtdynestimb_ablasso:xtdynestimb ablasso} {hline 2} Arellano-Bond
LASSO; {cmd:crossfit} turns on sample-splitting / cross-fitting (AB-LASSO-SS).

{marker options}{...}
{title:Options common to the GMM subcommands (dd, csdgmm)}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:ags(#)}}autoregressive order {it:p}; default {cmd:lags(1)}{p_end}
{synopt:{opt gmml:ags(min max)}}lag window for the GMM (level) instruments;
default {cmd:gmmlags(2 .)} (all available lags >= 2){p_end}
{synopt:{opt two:step}}two-step efficient GMM (the default){p_end}
{synopt:{opt one:step}}one-step GMM with a fully robust variance{p_end}
{synopt:{opt nowin:dmeijer}}suppress the Windmeijer (2005) finite-sample
correction of the two-step variance{p_end}
{synopt:{opt nota:ble}}suppress the output table{p_end}
{synopt:{opt graph}}draw a coefficient plot ({helpb xtdynestimb##graph:see below}){p_end}
{synopt:{opt graphn:ame(name)}}name for the graph{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Subcommand-specific options are documented on each subcommand's help page.

{marker dabss}{...}
{title:Debiased Arellano-Bond (DAB-SS)}

{pstd}
{cmd:xtdynestimb dabss} {it:depvar} [{it:indepvars}] {ifin} [{cmd:,}
{opt l:ags(#)} {opt gmml:ags(min max)} {opt one:step} {opt graph}] implements the
debiased Arellano-Bond estimator that splits the cross-section in half, estimates
AB on each half, and combines {it:2*AB(full) - mean of the two halves} to remove
the O({it:T/N}) many-moment bias (Chen, Chernozhukov & Fernandez-Val 2019,
applying the split-panel jackknife of Dhaene & Jochmans 2015). This is the
{cmd:DAB-SS} column of the AB-LASSO paper's Table 5.1. (For the fixed-effects /
within version of the split-panel jackknife see the {cmd:xtspj} package.)

{p 8 8 2}{cmd:. xtdynestimb dabss Y D Cvars, lags(4)}{p_end}

{marker breaks}{...}
{title:Structural-break / regime detection (Table A1 step)}

{pstd}
The empirical workflow of Chowdhury & Russell (2017) has {bf:two} outputs: first
the structural breaks are detected (their Table A1), then the break-robust
estimators are applied (their Table 7). {cmd:xtdynestimb breaks} performs the
first step:

{p 8 17 2}
{cmd:xtdynestimb breaks} {it:depvar} {ifin} [{cmd:,}
{opt max:breaks(#)} {opt min:length(#)} {opt notable}]

{pstd}
It aggregates {it:depvar} cross-sectionally (the mean across panel units at each
period) and applies a Bai & Perron (1998) dynamic-programming multiple-mean-shift
search, choosing the number of breaks by BIC. It reports the regimes, their date
ranges and the mean of {it:depvar} in each regime (the Table A1 layout), and
returns {cmd:r(regimes)}, {cmd:r(nbreaks)}, {cmd:r(nregimes)}. Use it to justify
the break-robust estimators. {opt minlength()} is the minimum regime length
(default 15% of {it:T}); {opt maxbreaks()} caps the number of breaks.

{p 8 8 2}{cmd:. xtdynestimb breaks loangrowth, minlength(5)}{p_end}

{marker table}{...}
{title:Comparison table (empirical-application layout)}

{pstd}
{cmd:xtdynestimb table} {it:depvar} [{it:indepvars}] {ifin} [{cmd:,}
{opt l:ags(#)} {opt gmml:ags(min max)} {opt est:imators(list)}
{opt longrun} {opt breaks} {opt one:step} {opt title(string)}] reproduces the
multi-estimator results table of an empirical paper (e.g. Chowdhury & Russell
2017, Table 7): one column per estimator, coefficients with significance stars
and standard errors, followed by a diagnostics block (units, observations,
instruments, Hansen J p-value, and the Arellano-Bond AR(1)/AR(2)
serial-correlation p-values).

{pstd}
{opt longrun} reports the {bf:long-run} coefficients of the regressors,
{it:b_x/(1-{c 83}a)}, with delta-method standard errors (the lagged-dependent
coefficient is left in short-run form). {opt srlr} reports {bf:both} a short-run
and a long-run row for each regressor (the AB-LASSO paper's Table 5.1 layout).
{opt breaks} prepends the Bai-Perron regime table (the Table A1 step) so the full
empirical workflow appears in one call.

{pstd}
{opt estimators()} tokens: {cmd:difference} (or {cmd:ab}), {cmd:system},
{cmd:ddback}, {cmd:ddforward}, {cmd:full}, {cmd:csdgmm}, {cmd:csdpartial},
{cmd:dabss}, {cmd:ablasso} (plain), and {cmd:ablasso}{it:K} for AB-LASSO-SS with
{it:K} folds (e.g. {cmd:ablasso2}, {cmd:ablasso5}). To reproduce the AB-LASSO
Table 5.1 use, with {cmd:lags(4)}:

{p 8 8 2}{cmd:. xtdynestimb table Y D Cvars, lags(4) srlr estimators(ablasso2 ablasso5 ab dabss)}{p_end}

{pstd}
{opt estimators()} chooses and orders the columns from:
{cmd:difference}, {cmd:system}, {cmd:ddback}, {cmd:ddforward}, {cmd:full},
{cmd:csdgmm}, {cmd:csdpartial}, {cmd:ablasso}. The default is the five
break-robust GMM estimators
{cmd:difference system ddback ddforward full}. Returns {cmd:r(coef)} and
{cmd:r(se)} (each {it:k} x #estimators).

{p 8 8 2}{cmd:. xtdynestimb table n w k, lags(1) gmmlags(2 5)}{p_end}
{p 8 8 2}{cmd:. xtdynestimb table n w, estimators(difference system full csdgmm ablasso)}{p_end}

{marker graph}{...}
{title:Visualization}

{pstd}
Every estimation can produce a dependency-free coefficient plot (point estimates
with confidence intervals):

{p 8 8 2}{cmd:. xtdynestimb dd y, graph}{p_end}
{p 8 8 2}{cmd:. xtdynestimb graph}    {it:(after any xtdynestimb fit)}{p_end}

{pstd}
For {helpb xtdynestimb_dd:dd} the {cmd:compare} option additionally draws a
side-by-side comparison of the persistence coefficient across the five variants:

{p 8 8 2}{cmd:. xtdynestimb dd y, compare graph}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtdynestimb} is an {cmd:e}-class command. Common results:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations used{p_end}
{synopt:{cmd:e(N_g)}}number of panel units used{p_end}
{synopt:{cmd:e(arlags)}}autoregressive order{p_end}
{synopt:{cmd:e(n_moments)}}number of moment conditions (GMM){p_end}
{synopt:{cmd:e(j)}, {cmd:e(j_df)}, {cmd:e(j_p)}}Hansen overid. statistic, df, p
(GMM){p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdynestimb}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:dd}, {cmd:csdgmm} or {cmd:ablasso}{p_end}
{synopt:{cmd:e(estimator)}}long estimator label{p_end}
{synopt:{cmd:e(depvar)}}, {cmd:e(indepvars)}, {cmd:e(ivar)}, {cmd:e(tvar)}{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficient vector and variance matrix{p_end}

{pstd}
See each subcommand's page for its full result list.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Break-robust Double-D GMM (all five variants compared){p_end}
{phang2}{cmd:. xtdynestimb dd n, lags(1) compare graph}{p_end}

{pstd}CSD-robust system GMM with regressor-only instruments{p_end}
{phang2}{cmd:. xtdynestimb csdgmm n w, variant(system) partial}{p_end}

{pstd}Arellano-Bond LASSO with cross-fitting in a long panel{p_end}
{phang2}{cmd:. xtdynestimb ablasso n, lags(2) crossfit kfold(5) nsplits(5) seed(123)}{p_end}

{pstd}Long-run effect and a follow-up specification test{p_end}
{phang2}{cmd:. xtdynestimb dd n, lags(1)}{p_end}
{phang2}{cmd:. nlcom _b[L1.n]/(1-_b[L1.n])}{p_end}
{phang2}{cmd:. predict double e, residuals}{p_end}
{phang2}{cmd:. xtdyntest csd, residuals(e)}{p_end}

{marker references}{...}
{title:References}

{phang}Chowdhury, R. A., and B. Russell. 2017. The Difference, System and
'Double-D' GMM panel estimators in the presence of structural breaks.
{it:Scottish Journal of Political Economy} 64(4): 373-395.{p_end}

{phang}Sarafidis, V. 2009. GMM estimation of short dynamic panel data models
with error cross-sectional dependence. MPRA Paper 25176, University of Munich.{p_end}

{phang}Chernozhukov, V., I. Fernandez-Val, C. Huang, and W. Wang. 2024.
Arellano-Bond LASSO estimator for dynamic linear panel models. cemmap working
paper CWP09/24.{p_end}

{phang}Arellano, M., and S. Bond. 1991. Some tests of specification for panel
data. {it:Review of Economic Studies} 58: 277-297.{p_end}

{phang}Blundell, R., and S. Bond. 1998. Initial conditions and moment
restrictions in dynamic panel data models. {it:Journal of Econometrics}
87: 115-143.{p_end}

{phang}Windmeijer, F. 2005. A finite sample correction for the variance of
linear efficient two-step GMM estimators. {it:Journal of Econometrics}
126: 25-51.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Companion package: {helpb xtdyntest} (specification tests for dynamic
panel GMM).{p_end}
