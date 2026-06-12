{smcl}
{* 10jun2026}{...}
{vieweralsosee "xtdynestimb" "help xtdynestimb"}{...}
{vieweralsosee "xtdynestimb dd" "help xtdynestimb_dd"}{...}
{vieweralsosee "xtdynestimb csdgmm" "help xtdynestimb_csdgmm"}{...}
{vieweralsosee "xtdynestimb ablasso" "help xtdynestimb_ablasso"}{...}
{vieweralsosee "xtdyntest" "help xtdyntest"}{...}
{viewerjumpto "Postestimation commands" "xtdynestimb_postestimation##commands"}{...}
{viewerjumpto "predict" "xtdynestimb_postestimation##predict"}{...}
{viewerjumpto "graph" "xtdynestimb_postestimation##graph"}{...}
{viewerjumpto "Long-run effects" "xtdynestimb_postestimation##lr"}{...}
{viewerjumpto "Specification tests" "xtdynestimb_postestimation##tests"}{...}
{viewerjumpto "Author" "xtdynestimb_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xtdynestimb postestimation} {hline 2} Postestimation tools for
{helpb xtdynestimb}

{pstd}({it:part of} {helpb xtdynestimb}.){p_end}

{marker commands}{...}
{title:Postestimation commands}

{pstd}
After any {helpb xtdynestimb} estimation the following standard tools are
available, because the command posts {cmd:e(b)} and {cmd:e(V)}:

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb xtdynestimb##graph:xtdynestimb graph}}coefficient plot{p_end}
{synopt:{helpb predict}}linear prediction or residuals (in levels){p_end}
{synopt:{helpb test}, {helpb testnl}}Wald tests of coefficients{p_end}
{synopt:{helpb lincom}, {helpb nlcom}}linear / nonlinear combinations (e.g.
long-run effects){p_end}
{synopt:{helpb estimates}}store, restore and compare models{p_end}
{synopt:{helpb xtdyntest}}specification tests on the residuals (companion
package){p_end}
{synoptline}

{marker predict}{...}
{title:predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 14 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}linear prediction in levels (the default){p_end}
{synopt:{opt res:iduals}}residuals in levels, {it:depvar} {c 45} xb{p_end}
{synoptline}

{pstd}
The prediction uses the level-equation coefficients, so the residuals are in the
original scale of {it:depvar} and are suitable as input to the residual-based
cross-sectional-dependence tests in {helpb xtdyntest}.

{marker graph}{...}
{title:Coefficient plot}

{pstd}
{cmd:xtdynestimb graph} (or the {cmd:graph} option at estimation) draws a
dependency-free plot of the point estimates with confidence intervals:

{p 8 8 2}{cmd:. xtdynestimb dd n, lags(1)}{p_end}
{p 8 8 2}{cmd:. xtdynestimb graph, name(mycoef)}{p_end}

{marker lr}{...}
{title:Long-run effects}

{pstd}
For an AR(1) model the long-run multiplier of a regressor {it:x} is
{it:b_x / (1 {c 45} a)} where {it:a} is the persistence coefficient. Use
{helpb nlcom}:

{p 8 8 2}{cmd:. xtdynestimb dd n w, lags(1)}{p_end}
{p 8 8 2}{cmd:. nlcom (lr_w: _b[w]/(1-_b[L1.n]))}{p_end}

{pstd}
For the persistence half-life or cumulative dynamics with {cmd:lags(2)}, combine
the lag coefficients similarly inside {cmd:nlcom}.

{marker tests}{...}
{title:Specification tests (companion package)}

{pstd}
Because {cmd:predict, residuals} returns level residuals, the
{helpb xtdyntest} battery can be run directly:

{p 8 8 2}{cmd:. xtdynestimb csdgmm n w, variant(system)}{p_end}
{p 8 8 2}{cmd:. predict double e, residuals}{p_end}
{p 8 8 2}{cmd:. xtdyntest csd, residuals(e)}    {it:// Pesaran CD, Frees, Friedman, BP-LM}{p_end}
{p 8 8 2}{cmd:. xtdyntest lee n, residuals(e)}  {it:// neglected-nonlinearity test}{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
