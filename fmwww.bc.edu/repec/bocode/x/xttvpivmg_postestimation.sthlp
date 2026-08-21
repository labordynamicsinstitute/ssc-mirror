{smcl}
{* *! version 1.0.0  19aug2026}{...}
{vieweralsosee "xttvpivmg" "help xttvpivmg"}{...}
{vieweralsosee "xttvpivmg methods" "help xttvpivmg_methods"}{...}
{viewerjumpto "Postestimation commands" "xttvpivmg_postestimation##cmds"}{...}
{viewerjumpto "predict" "xttvpivmg_postestimation##predict"}{...}
{viewerjumpto "Replay" "xttvpivmg_postestimation##replay"}{...}
{viewerjumpto "Working with the paths" "xttvpivmg_postestimation##paths"}{...}
{viewerjumpto "test, lincom and nlcom" "xttvpivmg_postestimation##test"}{...}
{viewerjumpto "Building your own figure" "xttvpivmg_postestimation##figure"}{...}
{viewerjumpto "Exporting a table" "xttvpivmg_postestimation##export"}{...}
{viewerjumpto "Author" "xttvpivmg_postestimation##author"}{...}

{title:Title}

{phang}
{bf:xttvpivmg postestimation} {hline 2} Postestimation tools for {helpb xttvpivmg}


{marker cmds}{title:Postestimation commands}

{pstd}
The following are available after {cmd:xttvpivmg}:

{synoptset 20 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb xttvpivmg_postestimation##predict:predict}}fitted values and residuals
using the time-varying mean-group coefficients{p_end}
{synopt:{helpb xttvpivmg}}replay the results, optionally at other dates{p_end}
{synopt:{helpb test}, {helpb lincom}, {helpb nlcom}}operate on the estimates at
{cmd:e(tref)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{helpb estat} subcommands, {helpb margins} and {helpb predictnl} are {bf:not}
supported: the model has a different coefficient vector at every date, so the
single {cmd:e(b)} they would use is only one slice of the results.


{marker predict}{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 14 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}linear prediction using bhat_MG(t) at each observation's own date;
the default{p_end}
{synopt:{opt r:esiduals}}{it:depvar} minus the linear prediction{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Unlike an ordinary estimation command, the prediction at observation (i,t) uses the
coefficient vector {bf:for that date}, bhat_MG(t), not a single fixed vector. The
prediction is therefore defined only for dates inside the reported window: rows
outside it, and rows outside {cmd:e(sample)}, receive missing values.

{pstd}
Note that this is the {it:mean-group} fit. It is not the fit of unit i's own
coefficient path bhat^IV_it, and residuals from it contain the coefficient
heterogeneity e_it as well as the disturbance u_it. That is deliberate: the
heterogeneity is precisely what the standard errors in eq. (17) are built from.

{pstd}{bf:Examples}{p_end}
{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), cv}{p_end}
{phang2}{cmd:. predict yhat, xb}{p_end}
{phang2}{cmd:. predict uhat, residuals}{p_end}
{phang2}{cmd:. xtline uhat, overlay legend(off)}{p_end}


{marker replay}{title:Replaying results}

{pstd}
Typing {cmd:xttvpivmg} with no arguments redisplays the results without
re-estimating {hline 2} useful for looking at other dates or another confidence
level after a slow cross-validated fit.

{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), cv}{space 4}// the expensive run{p_end}
{phang2}{cmd:. xttvpivmg, at(1998 2003 2008 2013)}{p_end}
{phang2}{cmd:. xttvpivmg, level(90) summary}{p_end}
{phang2}{cmd:. xttvpivmg, noheader}{p_end}

{pstd}
{opt at()} takes dates in {it:timevar} units and each must lie inside the reported
window; {opt summary} adds the path-summary table; {opt noheader} suppresses the
header block.


{marker paths}{title:Working with the estimated paths}

{pstd}
The estimator's real output is three aligned matrices:

{p2colset 8 22 24 2}{...}
{p2col :{cmd:e(bmg)}}{it:nrep} x k coefficient paths, columns named after the regressors{p_end}
{p2col :{cmd:e(semg)}}{it:nrep} x k standard errors, same layout{p_end}
{p2col :{cmd:e(tlist)}}{it:nrep} x 1 dates, row-aligned with both of the above{p_end}
{p2col :{cmd:e(bi)}}(N*{it:nrep}) x k per-unit paths, unit-major (only with {opt full}){p_end}
{p2colreset}{...}

{pstd}
Row r of {cmd:e(bmg)} is the estimate at date {cmd:e(tlist)}[r,1]. To bring them
into the dataset as variables:

{phang2}{cmd:. matrix B = e(bmg)}{p_end}
{phang2}{cmd:. matrix S = e(semg)}{p_end}
{phang2}{cmd:. matrix D = e(tlist)}{p_end}
{phang2}{cmd:. local xn "`e(xnames)'"}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double D, name(date)}{p_end}
{phang2}{cmd:. svmat double B, name(b)}{p_end}
{phang2}{cmd:. svmat double S, name(se)}{p_end}
{phang2}{cmd:. list in 1/5}{p_end}

{pstd}
{cmd:e(bi)} is stacked unit-major: rows 1..{it:nrep} are unit 1, rows
{it:nrep}+1..2*{it:nrep} are unit 2, and so on, with the units in sorted
{it:panelvar} order. To pull out unit i's path for regressor j:

{phang2}{cmd:. matrix BI = e(bi)}{p_end}
{phang2}{cmd:. local nrep = e(nrep)}{p_end}
{phang2}{cmd:. local i 3}{p_end}
{phang2}{cmd:. matrix path3 = BI[(`=(`i'-1)*`nrep'+1')..(`=`i'*`nrep''), 1...]}{p_end}

{pstd}
Inspecting the per-unit paths is the quickest way to see {it:why} a band is wide at
some date: the standard error in eq. (17) is nothing but the dispersion of these N
curves.


{marker test}{title:test, lincom and nlcom}

{pstd}
{cmd:e(b)} and {cmd:e(V)} hold the estimates at a single date, {cmd:e(tref)},
chosen with the {opt tref()} option and defaulting to the middle of the reported
window. This exists so that the standard inference commands work:

{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), tref(2008)}{p_end}
{phang2}{cmd:. test x2}{space 25}// is the 2008 coefficient zero?{p_end}
{phang2}{cmd:. lincom x1 + x2}{p_end}
{phang2}{cmd:. nlcom -_b[x1]/_b[x2]}{p_end}

{pstd}
Two warnings. First, {cmd:e(V)} is {bf:diagonal}: BMK's eq. (17) does define the
full k x k matrix Sigmahat_e(t), but only its diagonal is used for the reported
standard errors, and only the diagonal is posted here. Tests involving more than
one coefficient at a time therefore ignore their covariance and should be treated
as indicative only.

{pstd}
Second, choosing {opt tref()} after seeing the paths is data snooping. If you want
to test a coefficient at a particular date, pick the date for a substantive reason.


{marker figure}{title:Building your own figure}

{pstd}
The {opt graph} option produces a figure in the style of BMK's Figure 1. To build
your own with full control:

{phang2}{cmd:. xttvpivmg y x1 (x2 = z1 z2), cv}{p_end}
{phang2}{cmd:. matrix B = e(bmg)}{p_end}
{phang2}{cmd:. matrix S = e(semg)}{p_end}
{phang2}{cmd:. matrix D = e(tlist)}{p_end}
{phang2}{cmd:. local fmt "`e(tsfmt)'"}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double D, name(date)}{p_end}
{phang2}{cmd:. svmat double B, name(b)}{p_end}
{phang2}{cmd:. svmat double S, name(se)}{p_end}
{phang2}{cmd:. format date1 `fmt'}{p_end}
{phang2}{cmd:. gen lo = b2 - 1.96*se2}{p_end}
{phang2}{cmd:. gen hi = b2 + 1.96*se2}{p_end}
{phang2}{cmd:. twoway (rarea lo hi date1, color(navy%20) lwidth(none)) ///}{p_end}
{phang2}{cmd:         (line b2 date1, lcolor(navy) lwidth(medthick)), ///}{p_end}
{phang2}{cmd:      yline(0, lcolor(gs8)) legend(off) graphregion(color(white))}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
Column {it:j} of {cmd:e(bmg)} corresponds to word {it:j} of {cmd:e(xnames)}; the
constant, when present, is the last column.


{marker export}{title:Exporting a table}

{pstd}
Because the coefficient vector varies by date, the usual
{helpb estout}/{helpb esttab} workflow does not apply directly. Export the path
matrices instead:

{phang2}{cmd:. matrix R = e(tlist), e(bmg), e(semg)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double R, name(c)}{p_end}
{phang2}{cmd:. export delimited using "tvpaths.csv", replace}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}
For a journal table at selected dates, {cmd:xttvpivmg, at({it:numlist})} already
prints exactly that; capture it with {helpb log} or {helpb estout} of the replayed
output.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}


{title:Also see}

{psee}
{help xttvpivmg:xttvpivmg}, {help xttvpivmg_methods:xttvpivmg methods}
{p_end}
