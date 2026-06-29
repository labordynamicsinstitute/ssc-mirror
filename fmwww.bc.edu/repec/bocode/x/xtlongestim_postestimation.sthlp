{smcl}
{* *! version 1.0.0  26jun2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtlongestim" "help xtlongestim"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Postestimation commands" "xtlongestim_postestimation##commands"}{...}
{viewerjumpto "Stored results" "xtlongestim_postestimation##results"}{...}
{viewerjumpto "Examples" "xtlongestim_postestimation##examples"}{...}
{viewerjumpto "Author" "xtlongestim_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xtlongestim postestimation} {hline 2} Postestimation tools for {helpb xtlongestim}


{marker commands}{...}
{title:Postestimation commands}

{pstd}
The following standard postestimation commands are available after {cmd:xtlongestim}.

{synoptset 20 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb estat summarize}}summary of the estimation sample{p_end}
{synopt:{helpb estimates}}cataloging of estimation results{p_end}
{synopt:{helpb lincom}}point estimates, std. errors, tests of linear combinations of the posted long-run coefficients{p_end}
{synopt:{helpb test}, {helpb testnl}}Wald tests on the posted long-run coefficients{p_end}
{synoptline}

{pstd}
{cmd:xtlongestim} posts, in {cmd:e(b)}/{cmd:e(V)}, the long-run coefficients of the
{it:primary} method (the first method in {opt methods()} that has a long-run row;
the default primary method is {cmd:mg}). Linear/nonlinear postestimation therefore
operates on that estimator. Typing {cmd:xtlongestim} with no arguments {it:replays}
the full comparison table.

{pstd}
The complete set of estimates from every requested method is always available in the
matrices {cmd:e(LR_b)} / {cmd:e(LR_se)} (long-run, one row per method) and
{cmd:e(SR_b)} / {cmd:e(SR_se)} (mean short-run, one row per method). The row order is

{p 8 8 2}{cmd:e(LR_b)}: {cmd:mg nbc dbc1 dbc2 bsbc bcmg ebayes hbayes pols}{p_end}
{p 8 8 2}{cmd:e(SR_b)}: {cmd:pols mg bcmg ebayes hbayes}{p_end}

{pstd}
Rows for methods that were not requested contain missing values.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtlongestim invest mvalue kstock, methods(all)}{p_end}

{pstd}Replay the comparison table:{p_end}
{phang2}{cmd:. xtlongestim}{p_end}

{pstd}Wald test on the posted (primary) long-run coefficients:{p_end}
{phang2}{cmd:. test mvalue = 0}{p_end}

{pstd}Pull the DBC1 long-run estimate of {cmd:mvalue} out of the result matrix:{p_end}
{phang2}{cmd:. matrix list e(LR_b)}{p_end}
{phang2}{cmd:. display el("e(LR_b)", 3, 1)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
