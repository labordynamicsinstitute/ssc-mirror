{smcl}
{* 10jun2026}{...}
{vieweralsosee "xtdynestimb" "help xtdynestimb"}{...}
{vieweralsosee "xtdynestimb dd" "help xtdynestimb_dd"}{...}
{vieweralsosee "xtdynestimb ablasso" "help xtdynestimb_ablasso"}{...}
{vieweralsosee "xtdynestimb postestimation" "help xtdynestimb_postestimation"}{...}
{vieweralsosee "xtdyntest syr" "help xtdyntest"}{...}
{viewerjumpto "Syntax" "xtdynestimb_csdgmm##syntax"}{...}
{viewerjumpto "Description" "xtdynestimb_csdgmm##description"}{...}
{viewerjumpto "Options" "xtdynestimb_csdgmm##options"}{...}
{viewerjumpto "Stored results" "xtdynestimb_csdgmm##results"}{...}
{viewerjumpto "Examples" "xtdynestimb_csdgmm##examples"}{...}
{viewerjumpto "References" "xtdynestimb_csdgmm##references"}{...}
{viewerjumpto "Author" "xtdynestimb_csdgmm##author"}{...}
{title:Title}

{phang}
{bf:xtdynestimb csdgmm} {hline 2} GMM estimation of short dynamic panels with
error cross-sectional dependence (Sarafidis 2009)

{pstd}({it:part of} {helpb xtdynestimb}. See also {helpb xtdynestimb_dd:dd},
{helpb xtdynestimb_ablasso:ablasso},
{helpb xtdynestimb_postestimation:postestimation}.){p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtdynestimb csdgmm} {it:depvar} [{it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt var:iant(type)}}{cmd:difference} or {cmd:system}; default
{cmd:system}{p_end}
{synopt:{opt l:ags(#)}}autoregressive order {it:p}; default {cmd:lags(1)}{p_end}
{synopt:{opt gmml:ags(min max)}}lag window for the GMM instruments; default
{cmd:gmmlags(2 .)}{p_end}

{syntab:CSD robustness}
{synopt:{opt partial}}use {bf:regressor-only} instruments (drop all
lagged-{it:y} instruments); requires {it:indepvars}{p_end}
{synopt:{opt nodem:ean}}do {it:not} time-demean (turns the CSD correction off;
for comparison only){p_end}

{syntab:Estimator}
{synopt:{opt two:step}}two-step efficient GMM (default){p_end}
{synopt:{opt one:step}}one-step GMM, robust variance{p_end}
{synopt:{opt nowin:dmeijer}}no Windmeijer two-step correction{p_end}

{syntab:Reporting}
{synopt:{opt graph}}coefficient plot{p_end}
{synopt:{opt graphn:ame(name)}}name for the graph{p_end}
{synopt:{opt nota:ble}}suppress the output table{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdynestimb csdgmm} estimates a short dynamic panel by GMM when the errors
are {bf:cross-sectionally dependent}. Under a common-factor (strong) dependence
structure the standard Arellano-Bond / Blundell-Bond lagged-level instruments are
correlated with the errors and the estimator is inconsistent (Sarafidis 2009;
Sarafidis & Robertson 2009).

{pstd}
The command applies the Sarafidis (2009) remedy in two parts:

{phang2}1. {bf:Cross-sectional (time) demeaning.} Each variable is expressed in
deviations from its cross-sectional mean at each time period, which removes
common time effects and (approximately) the common-factor component of the
errors before the usual difference / system GMM moment conditions are formed.{p_end}

{phang2}2. {bf:Partial (regressor-only) instruments} ({cmd:partial}). When the
dependence is heterogeneous, even demeaning may be insufficient; restricting the
instrument set to the strictly exogenous regressors (dropping all lagged-{it:y}
instruments) yields an estimator that Sarafidis, Yamagata & Robertson (2009) show
to be a reliable alternative under heterogeneous error CSD.{p_end}

{pstd}
Pair this estimator with {helpb xtdyntest}'s {cmd:syr} and {cmd:csd} subcommands
to test for residual cross-sectional dependence after estimation.

{marker options}{...}
{title:Options}

{phang}{opt variant(type)} selects {cmd:difference} (Sarafidis eq. 17) or
{cmd:system} (eq. 26) GMM on the demeaned data.{p_end}

{phang}{opt partial} keeps only the regressor instruments. With {cmd:system} the
level equation is then instrumented by the regressors only. Requires at least one
{it:indepvar}.{p_end}

{phang}{opt nodemean} disables the time-demeaning so you can see the size of the
CSD correction relative to ordinary difference/system GMM.{p_end}

{phang}{opt lags()}, {opt gmmlags()}, {opt twostep}, {opt onestep},
{opt nowindmeijer}, {opt level()} behave as in {helpb xtdynestimb_dd:dd}.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}In addition to the common {helpb xtdynestimb##results:e()} results:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(j)}, {cmd:e(j_df)}, {cmd:e(j_p)}}Hansen J statistic, df, p-value{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(variant)}}variant used{p_end}
{synopt:{cmd:e(demean)}}transform applied{p_end}
{synopt:{cmd:e(partial)}}instrument set description{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}CSD-robust system GMM (time-demeaned){p_end}
{phang2}{cmd:. xtdynestimb csdgmm n w k, variant(system)}{p_end}

{pstd}Regressor-only (partial) instruments under heterogeneous CSD{p_end}
{phang2}{cmd:. xtdynestimb csdgmm n w k, variant(system) partial}{p_end}

{pstd}Test for residual CSD afterwards{p_end}
{phang2}{cmd:. predict double e, residuals}{p_end}
{phang2}{cmd:. xtdyntest csd, residuals(e)}{p_end}

{marker references}{...}
{title:References}

{phang}Sarafidis, V. 2009. GMM estimation of short dynamic panel data models
with error cross-sectional dependence. MPRA Paper 25176, University of Munich.{p_end}

{phang}Sarafidis, V., T. Yamagata, and D. Robertson. 2009. A test of cross
section dependence for a linear dynamic panel model with regressors.
{it:Journal of Econometrics} 148: 149-161.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
