{smcl}
{* 10jun2026}{...}
{vieweralsosee "xtdynestimb" "help xtdynestimb"}{...}
{vieweralsosee "xtdynestimb csdgmm" "help xtdynestimb_csdgmm"}{...}
{vieweralsosee "xtdynestimb ablasso" "help xtdynestimb_ablasso"}{...}
{vieweralsosee "xtdynestimb postestimation" "help xtdynestimb_postestimation"}{...}
{viewerjumpto "Syntax" "xtdynestimb_dd##syntax"}{...}
{viewerjumpto "Description" "xtdynestimb_dd##description"}{...}
{viewerjumpto "Moment conditions" "xtdynestimb_dd##moments"}{...}
{viewerjumpto "Options" "xtdynestimb_dd##options"}{...}
{viewerjumpto "Stored results" "xtdynestimb_dd##results"}{...}
{viewerjumpto "Examples" "xtdynestimb_dd##examples"}{...}
{viewerjumpto "References" "xtdynestimb_dd##references"}{...}
{viewerjumpto "Author" "xtdynestimb_dd##author"}{...}
{title:Title}

{phang}
{bf:xtdynestimb dd} {hline 2} Difference, System and {it:Double-D} GMM panel
estimators in the presence of structural breaks (Chowdhury & Russell 2017)

{pstd}({it:part of} {helpb xtdynestimb}. See also {helpb xtdynestimb_csdgmm:csdgmm},
{helpb xtdynestimb_ablasso:ablasso}, {helpb xtdynestimb_postestimation:postestimation}.){p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtdynestimb dd} {it:depvar} [{it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt var:iant(type)}}moment-condition set: {cmd:difference},
{cmd:system}, {cmd:ddback}, {cmd:ddforward} or {cmd:full}; default {cmd:full}{p_end}
{synopt:{opt l:ags(#)}}autoregressive order {it:p}; default {cmd:lags(1)}{p_end}
{synopt:{opt gmml:ags(min max)}}lag window for the level instruments; default
{cmd:gmmlags(2 .)}{p_end}

{syntab:Estimator}
{synopt:{opt two:step}}two-step efficient GMM (default){p_end}
{synopt:{opt one:step}}one-step GMM, robust variance{p_end}
{synopt:{opt nowin:dmeijer}}no Windmeijer two-step correction{p_end}

{syntab:Reporting}
{synopt:{opt compare}}estimate and tabulate all five variants together{p_end}
{synopt:{opt graph}}coefficient plot (or variant comparison with {cmd:compare}){p_end}
{synopt:{opt graphn:ame(name)}}name for the graph{p_end}
{synopt:{opt nota:ble}}suppress the output table{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdynestimb dd} implements the family of GMM estimators in Chowdhury &
Russell (2017) for the dynamic panel model when the fixed effects are subject to
{bf:structural (mean) breaks}. Such breaks add a non-zero term to the usual
Arellano-Bond and Blundell-Bond moment conditions, biasing the difference and
system GMM estimators. The paper proposes additional moment conditions in which
{bf:both the instruments and the estimating equation are in first differences}
({it:double-difference}, hence "double-D"), which remain valid whether or not
there is a break and whether or not the break is common across units.

{pstd}
The lagged dependent variable(s) are generated automatically according to
{cmd:lags()}. Any {it:indepvars} are treated as strictly exogenous and enter the
equation and the instrument set in the appropriate transform.

{marker moments}{...}
{title:Moment conditions and variants}

{pstd}
The five variants correspond to Table 1 of Chowdhury & Russell (2017):

{p2colset 8 28 30 2}{...}
{p2col:{bf:variant}}{bf:moment conditions used}{p_end}
{p2col:{cmd:difference}}(1) {it:E[y_i,t-s {c 183} Dv_it] = 0}  (Arellano-Bond){p_end}
{p2col:{cmd:system}}(1) + (2) {it:E[Dy_i,t-1 {c 183} (v_it+eta_i)] = 0}  (Blundell-Bond){p_end}
{p2col:{cmd:ddback}}(3) {it:E[Dy_i,t-s {c 183} Dv_it] = 0},  {it:S>=2}  (backward double-D){p_end}
{p2col:{cmd:ddforward}}(4) {it:E[Dy_i,t+s {c 183} Dv_it] = 0},  {it:S>=2}  (forward double-D){p_end}
{p2col:{cmd:full}}(1)+(2)+(3)+(4)  (full system; most efficient){p_end}
{p2colreset}{...}

{pstd}
Moment conditions (3) and (4) are the break-robust additions. {cmd:full} stacks
all four and, in the simulations of Chowdhury & Russell (2017), recovers the
true autoregressive parameter most accurately in the presence of breaks. When
persistence is low, the pure double-D variants can suffer weak-instrument bias;
use {cmd:full} or {cmd:system} in that case.

{marker options}{...}
{title:Options}

{phang}{opt variant(type)} chooses the moment-condition set (see above).{p_end}

{phang}{opt lags(#)} sets the autoregressive order {it:p}. With {cmd:lags(2)}
the model includes {it:y_i,t-1} and {it:y_i,t-2}.{p_end}

{phang}{opt gmmlags(min max)} limits the lag depth of the level (Arellano-Bond)
instruments to control instrument proliferation, exactly as the lag range does
in {helpb xtabond2}. The minimum must be at least 2.{p_end}

{phang}{opt twostep}, {opt onestep}, {opt nowindmeijer} control the GMM step and
the variance estimator. The default is two-step with the Windmeijer (2005)
correction. {cmd:onestep} reports a fully robust one-step variance.{p_end}

{phang}{opt compare} re-estimates the model under all five variants and prints a
compact table of the first-lag (persistence) coefficient, its standard error and
the number of moments for each, so the break-sensitivity of difference/system
relative to the double-D variants is visible at a glance. It also returns
{cmd:r(compare)}.{p_end}

{phang}{opt graph} draws a coefficient plot; with {cmd:compare} it draws the
five-variant comparison of the persistence coefficient.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}In addition to the common {helpb xtdynestimb##results:e()} results,
{cmd:dd} stores:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(j)}, {cmd:e(j_df)}, {cmd:e(j_p)}}Hansen J statistic, df, p-value{p_end}
{synopt:{cmd:e(n_moments)}}number of moment conditions{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(variant)}}variant used{p_end}
{synopt:{cmd:e(step)}, {cmd:e(vce)}, {cmd:e(gmmlags)}}estimator settings{p_end}

{pstd}With {cmd:compare}, {cmd:r(compare)} is a 5{c 215}5 matrix (rows = variants;
columns = b, se, z, p, moments).{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Full break-robust estimator{p_end}
{phang2}{cmd:. xtdynestimb dd n, lags(1)}{p_end}

{pstd}Compare all five variants and plot{p_end}
{phang2}{cmd:. xtdynestimb dd n, lags(1) compare graph}{p_end}

{pstd}AR(2) with capped instruments, one-step robust{p_end}
{phang2}{cmd:. xtdynestimb dd n w, lags(2) gmmlags(2 4) variant(full) onestep}{p_end}

{marker references}{...}
{title:References}

{phang}Chowdhury, R. A., and B. Russell. 2017. The Difference, System and
'Double-D' GMM panel estimators in the presence of structural breaks.
{it:Scottish Journal of Political Economy} 64(4): 373-395.{p_end}

{phang}Windmeijer, F. 2005. A finite sample correction for the variance of
linear efficient two-step GMM estimators. {it:Journal of Econometrics}
126: 25-51.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
