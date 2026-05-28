{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "nqar"                    "help nqar"}{...}
{vieweralsosee "dnqr"                    "help dnqr"}{...}
{vieweralsosee "dnqr_impulse"            "help dnqr_impulse"}{...}
{vieweralsosee "dnqr_simulate"           "help dnqr_simulate"}{...}
{vieweralsosee "dnqr_postestimation"     "help dnqr_postestimation"}{...}
{viewerjumpto "Syntax"            "dnqr_plot##syntax"}{...}
{viewerjumpto "Description"       "dnqr_plot##description"}{...}
{viewerjumpto "Options"           "dnqr_plot##options"}{...}
{viewerjumpto "Examples"          "dnqr_plot##examples"}{...}
{viewerjumpto "Also see"          "dnqr_plot##alsosee"}{...}

{title:Title}

{p2colset 5 20 24 2}{...}
{p2col :{bf:dnqr_plot} {hline 2}}Quantile coefficient plot with confidence bands (post-estimation){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:dnqr_plot} [{it:varlist}] [, {it:options}]

{p 4 6 2}
{it:varlist} lists the regressors to plot (default: all network/dynamic
terms plus nodal Z).  Allowed names match the row names of {cmd:e(b_q)}
({bf:WY}, {bf:WY_L1}, {bf:Y_L1}, names of Z-vars, names of F-vars and
their lags).


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth nc:ols(#)}}columns in the combined figure (default 3){p_end}
{synopt :{opt c:olor(string)}}line colour (default {bf:navy}){p_end}
{synopt :{opt bc:olor(string)}}band colour, supports the {it:c%opacity} syntax (default {bf:ltblue%40}){p_end}
{synopt :{opt l:evel(#)}}override the CI level for the title (the band itself comes from e(lo_q)/e(hi_q)){p_end}
{synopt :{opt t:itle(string)}}custom figure title{p_end}
{synopt :{opt sch:eme(string)}}graphics scheme (default {bf:s2color}){p_end}
{synopt :{opt na:me(string)}}graph name (default {bf:dnqrplot}){p_end}
{synopt :{opt s:aving(filename)}}save the combined graph{p_end}
{synopt :{opt nodraw}}suppress on-screen display{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dnqr_plot} draws the quantile coefficient process for each requested
regressor: a solid line for the point estimate and a shaded ribbon for
the confidence band, with a dashed zero-line.  Panels are arranged in a
grid by {cmd:graph combine}.  The figure style follows the Koenker (2005)
rqs-plot convention and matches the {it:DNQR} paper figures.  It can be
used immediately after {help nqar:nqar} or {help dnqr:dnqr}.


{marker options}{...}
{title:Options}

{phang}{opt ncols(#)} number of columns in the combined panel.

{phang}{opt color(string)} colour of the point-estimate line.

{phang}{opt bcolor(string)} colour of the shaded ribbon.  Stata 14+ accepts
opacity, e.g. {cmd:bcolor(navy%30)}.

{phang}{opt level(#)} cosmetic only; relabels the title.

{phang}{opt title(string)} overrides the default title.

{phang}{opt scheme(string)} graphics scheme.

{phang}{opt name(string)} name of the resulting graph object.

{phang}{opt saving(filename)} saves the combined graph to disk.


{marker examples}{...}
{title:Examples}

{phang}{cmd}. dnqr y, network(W) rowstd q(0.1 0.25 0.5 0.75 0.9) z(Z1 Z2) factors(F1 F2){p_end}
{phang}{cmd}. dnqr_plot{p_end}

{phang}{cmd}. * subset and custom colour{txt}{p_end}
{phang}{cmd}. dnqr_plot WY WY_L1 Y_L1, ncols(3) color(maroon) bcolor(orange%30){p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
Estimators: {help nqar}, {help dnqr}{break}
Other post-estimation: {help dnqr_impulse},
{help dnqr_postestimation}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
