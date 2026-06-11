{smcl}
{* *! version 1.0.0  03jun2026}{...}
{vieweralsosee "tnardll" "help tnardll"}{...}
{vieweralsosee "tnardlldiag" "help tnardlldiag"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "tnardllmult##syntax"}{...}
{viewerjumpto "Description" "tnardllmult##description"}{...}
{viewerjumpto "Options" "tnardllmult##options"}{...}
{viewerjumpto "Remarks" "tnardllmult##remarks"}{...}
{viewerjumpto "Examples" "tnardllmult##examples"}{...}
{viewerjumpto "Stored results" "tnardllmult##results"}{...}
{viewerjumpto "Author" "tnardllmult##author"}{...}
{title:Title}

{phang}
{bf:tnardllmult} {hline 2} Cumulative dynamic multipliers after {help tnardll:tnardll}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tnardllmult}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt h:orizon(#)}}horizon over which to trace the response; default {cmd:horizon(24)}{p_end}
{synopt:{opt graph}}draw the multiplier paths{p_end}
{synopt:{opt notab:le}}suppress the multiplier table{p_end}

{syntab:Graph}
{synopt:{opt sav:ing(filename)}}save the graph to {it:filename}{p_end}
{synopt:{opt tit:le(string)}}graph title{p_end}
{synopt:{it:twoway_options}}any options of {helpb twoway} (e.g. {cmd:scheme()}, {cmd:xlabel()}){p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:tnardllmult} is for use after {helpb tnardll}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tnardllmult} computes and (optionally) plots the {it:cumulative dynamic
multipliers} of the threshold ARDL model fitted by {helpb tnardll}.  For each
regime {it:s} it simulates the response of the {it:level} of the dependent
variable to a unit permanent change in that regime's partial-sum process
{it:x}{sup:(s)}, traced out from horizon 0 to {opt horizon()}.

{pstd}
As the horizon grows each multiplier converges to the regime's long-run
coefficient

{p 8 8 2}
{it:beta}{sup:(s)} = {c -(} {it:theta}{sup:(s)} / {it:rho},

{pstd}
exactly the quantities reported in the long-run table of {helpb tnardll}.  When
the model has {bf:S = 2} regimes the routine also returns the {it:difference
path} (regime 1 {c -} regime 2), which summarises the asymmetric speed and shape
of adjustment to positive versus negative movements in the threshold variable.

{marker options}{...}
{title:Options}

{phang}
{opt horizon(#)} sets the number of periods over which the multipliers are
traced.  The default is {cmd:horizon(24)}.  Must be a positive integer.

{phang}
{opt graph} requests a line plot of the multiplier paths (one line per regime,
plus the dashed difference path when S = 2), with a reference line at zero.

{phang}
{opt notable} suppresses the printed table of multipliers.

{phang}
{opt saving(filename)} saves the graph to disk (passed to {helpb graph save});
implies {opt graph}.

{phang}
{opt title(string)} overrides the default graph title.

{phang}
{it:twoway_options} are passed through to {helpb twoway}.

{marker remarks}{...}
{title:Remarks}

{pstd}
The simulation uses the structural pieces stored by {helpb tnardll} in
{cmd:e(rho)}, {cmd:e(theta)}, {cmd:e(pimat)} and (when {it:p}>1) {cmd:e(phi)}.
It applies a one-unit step to regime {it:s} only, holds all other regimes at
zero, and accumulates the implied path of {cmd:D.}{it:depvar} into the level
response.  Because the multipliers are deterministic transformations of the
fitted coefficients no standard errors are produced; quantify uncertainty by
{helpb bootstrap}-ing the whole {helpb tnardll} call if required.

{pstd}
The table prints every horizon up to 12 and every fourth horizon thereafter
(plus the final horizon) to stay compact; the full path is always returned in
{cmd:r(mult)}.

{marker examples}{...}
{title:Examples}

{pstd}Fit the model, then trace and plot 36-period multipliers:{p_end}

{phang2}{cmd:. tnardll y x z, lags(2 2) qlr}{p_end}
{phang2}{cmd:. tnardllmult, horizon(36) graph}{p_end}

{pstd}Table only, longer horizon, save the figure:{p_end}

{phang2}{cmd:. tnardllmult, horizon(60) graph saving(mymults.gph) title("Asymmetric adjustment")}{p_end}

{pstd}Recover the returned matrix for further work:{p_end}

{phang2}{cmd:. tnardllmult, notable}{p_end}
{phang2}{cmd:. matrix M = r(mult)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:tnardllmult} stores the following in {cmd:r()}:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(mult)}}({opt horizon()}+1) {c -} by {c -} (1 + S [+1 if S=2]) matrix;
column 1 is the horizon, the next S columns are the regime multipliers, and for
S=2 a final {cmd:diff} column holds the regime-1 {c -} regime-2 path{p_end}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}See {helpb tnardll} for the model, references, and the full list of
stored estimation results.{p_end}

{marker alsosee}{...}
{title:Also see}

{psee}
Estimation:  {helpb tnardll}{p_end}

{psee}
Postestimation:  {helpb tnardlldiag} (residual diagnostics){p_end}
