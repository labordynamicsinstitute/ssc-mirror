{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "nqar"                    "help nqar"}{...}
{vieweralsosee "dnqr"                    "help dnqr"}{...}
{vieweralsosee "dnqr_plot"               "help dnqr_plot"}{...}
{vieweralsosee "dnqr_impulse"            "help dnqr_impulse"}{...}
{vieweralsosee "dnqr_simulate"           "help dnqr_simulate"}{...}
{viewerjumpto "Postestimation tools"  "dnqr_postestimation##tools"}{...}
{viewerjumpto "Stored e()"            "dnqr_postestimation##stored"}{...}
{viewerjumpto "Replaying results"     "dnqr_postestimation##replay"}{...}
{viewerjumpto "esttab integration"    "dnqr_postestimation##esttab"}{...}

{title:Title}

{p2colset 5 28 32 2}{...}
{p2col :{bf:dnqr postestimation} {hline 2}}Postestimation tools for {help nqar:nqar} and {help dnqr:dnqr}{p_end}
{p2colreset}{...}


{marker tools}{...}
{title:Postestimation tools}

{pstd}The following post-estimation commands are available after a
successful {help nqar} or {help dnqr} fit.

{p2colset 5 28 32 2}{...}
{p2col :{help dnqr_plot:dnqr_plot}}quantile-coefficient plot with confidence bands{p_end}
{p2col :{help dnqr_impulse:dnqr_impulse}}tail-event impulse response (network propagation){p_end}
{p2col :{cmd:dnqr}/{cmd:nqar} (without arguments)}replay the stored results table{p_end}
{p2col :{help estimates}}save, restore, compare estimation results{p_end}
{p2colreset}{...}


{marker stored}{...}
{title:Stored results consumed by the postestimation tools}

{pstd}Both {cmd:nqar} and {cmd:dnqr} expose the following matrices
indexed by quantile, which are the primary inputs to the postestimation
commands.

{synoptset 18 tabbed}{...}
{synopt:{cmd:e(quantile)}}1 x q vector of quantiles{p_end}
{synopt:{cmd:e(b_q)}}kxq matrix of coefficients (rows are regressors){p_end}
{synopt:{cmd:e(se_q)}}kxq matrix of Powell standard errors{p_end}
{synopt:{cmd:e(t_q)}}z-statistics{p_end}
{synopt:{cmd:e(p_q)}}two-sided p-values{p_end}
{synopt:{cmd:e(lo_q)}, {cmd:e(hi_q)}}confidence bounds (used by {cmd:dnqr_plot}){p_end}
{synopt:{cmd:e(alphahat)}}({cmd:dnqr} only) IVQR grid minimum per tau{p_end}


{marker replay}{...}
{title:Replaying results}

{pstd}
Type {cmd:nqar} or {cmd:dnqr} with no arguments to redisplay the boxed
estimation table from the previous run, e.g.

{phang2}{cmd}. nqar y, network(W) rowstd q(0.1 0.5 0.9){txt}{p_end}
{phang2}{cmd}. nqar          // redisplay{txt}{p_end}


{marker esttab}{...}
{title:Integration with esttab / estout}

{pstd}
{cmd:dnqr} and {cmd:nqar} are e-class commands so they cooperate with
{cmd:estimates store} and {help estout##esttab:esttab}.  Because the
package fits {it:multiple} quantiles in one run, the easiest workflow
is to call the estimator separately for each tau and store the results
under tau-specific names, then combine them in a single {cmd:esttab}
table:

{phang2}{cmd}. foreach q in 0.10 0.25 0.50 0.75 0.90 {c -(}{txt}{p_end}
{phang2}{cmd}.     dnqr y, network(W) rowstd quantile(`q') notable{txt}{p_end}
{phang2}{cmd}.     estimates store dnqr_`= 100*`q'`{txt}{p_end}
{phang2}{cmd}. {c )-}{txt}{p_end}
{phang2}{cmd}. esttab dnqr_10 dnqr_25 dnqr_50 dnqr_75 dnqr_90,{break}
            se star(* 0.10 ** 0.05 *** 0.01) booktabs{txt}{p_end}


{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
Estimators: {help nqar}, {help dnqr}{break}
Other postestimation: {help dnqr_plot}, {help dnqr_impulse}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
