{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "xtkpybreak" "help xtkpybreak"}{...}
{vieweralsosee "xtkpybreak cce" "help xtkpybreak_cce"}{...}
{vieweralsosee "xtkpybreak break" "help xtkpybreak_break"}{...}
{viewerjumpto "Postestimation" "xtkpybreak_postestimation##post"}{...}
{viewerjumpto "coefplot" "xtkpybreak_postestimation##coefplot"}{...}
{viewerjumpto "Examples" "xtkpybreak_postestimation##examples"}{...}
{viewerjumpto "Author" "xtkpybreak_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xtkpybreak postestimation} {hline 2} Postestimation tools for
{helpb xtkpybreak}

{marker post}{...}
{title:Postestimation commands}

{pstd}
Because {cmd:xtkpybreak} is an {help estcom:e()-class estimation command} that
posts {bf:e(b)} and {bf:e(V)}, the standard postestimation machinery works after
either subcommand:

{synoptset 26 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt :{helpb estimates}}store, restore, and tabulate results across models{p_end}
{synopt :{helpb test}, {helpb testnl}}Wald tests of the posted coefficients{p_end}
{synopt :{helpb lincom}, {helpb nlcom}}linear / nonlinear combinations{p_end}
{synopt :{stata "help coefplot":coefplot}}coefficient plots (SSC; not required){p_end}
{synoptline}

{pstd}
{bf:What is posted.}

{phang2}o After {helpb xtkpybreak_cce:xtkpybreak cce}: {bf:e(b)} is the CCEMG
estimator by default (or CCEP with {opt estimator(pooled)}); coefficients are
named by the regressors. The alternative estimator and the per-panel slopes are
in {bf:e(b_pooled)}, {bf:e(b_mg)} and {bf:e(b_i)}.{p_end}

{phang2}o After {helpb xtkpybreak_break:xtkpybreak break}: {bf:e(b)} stacks the
regime mean-group slopes with equation names {bf:r1}, {bf:r2}, ...,
{bf:r(m+1)}. To test whether a slope changed across a break, contrast the
regimes, e.g. {cmd:test [r1]x = [r2]x}. Break dates are in {bf:e(breakdates)}.{p_end}

{marker coefplot}{...}
{title:Built-in graphs}

{pstd}
Both subcommands can draw journal-style graphs directly at estimation time
(no extra command needed):

{synoptset 26 tabbed}{...}
{synopt :{opt coefplot} (cce)}per-panel slope dispersion with the CCEMG line and
band{p_end}
{synopt :{opt factorplot} (cce)}cross-section-average factor proxies over time{p_end}
{synopt :{opt breakplot} (break)}cross-section average of {it:depvar} with break
dates marked{p_end}
{synopt :{opt coefevolution} (break)}regime step plot of the mean-group slope
with a confidence band{p_end}

{pstd}
Graphs are saved under the {opt name(stub)} you supply, so they can be combined
with {helpb graph combine} into a dashboard.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}CCE, then a Wald test and a stored comparison{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock}{p_end}
{phang2}{cmd:. estimates store CCEMG}{p_end}
{phang2}{cmd:. test mvalue kstock}{p_end}

{pstd}Break model, then test slope change across the break{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) coefevolution}{p_end}
{phang2}{cmd:. test [r1]mvalue = [r2]mvalue}{p_end}
{phang2}{cmd:. matrix list e(breakdates)}{p_end}

{pstd}Combine the built-in graphs into one figure{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock, coefplot factorplot name(a)}{p_end}
{phang2}{cmd:. xtkpybreak break invest mvalue kstock, nbreaks(1) breakplot coefevolution name(b)}{p_end}
{phang2}{cmd:. graph combine a_coef a_factor b_break b_evo, cols(2)}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
