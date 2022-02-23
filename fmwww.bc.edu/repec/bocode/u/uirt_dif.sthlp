{smcl}
{* *! version 1.1 2022.01.25}{...}
{viewerjumpto "Syntax" "uirt_dif##syntax"}{...}
{viewerjumpto "Description" "uirt_dif##description"}{...}
{viewerjumpto "Options" "uirt_dif##options"}{...}
{viewerjumpto "Examples" "uirt_dif##examples"}{...}
{viewerjumpto "Stored results" "uirt_dif##results"}{...}
{viewerjumpto "References" "uirt_dif##references"}{...}
{cmd:help uirt_dif}
{hline}

{title:Title}

{phang}
{bf:uirt_dif} {hline 2} Postestimation command of {helpb uirt} to perform DIF analysis

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_dif} [{varlist}]  [{cmd:,}{it:{help uirt_dif##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run.
If {it:varlist} is skipped or asterisk * is used, {cmd:uirt_dif} will either display the results that are currently stored in {cmd:e(dif_results)} matrix
(display mode), or it will conduct DIF analysis on all items declared in the main list of items of current {cmd:uirt} run (estimation mode). 
This behavior depends on whether any DIF analysis was produced by current uirt run or not.

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt f:ormat(str)}} file format for DIF graphs (png|gph|eps); default: format(png) {p_end}
{synopt:{opt c:olors(str)}} color names to override default plot colors used in DIF graphs  {p_end}
{synopt:{opth tw(twoway_options)}} twoway graph options to override default graph layout {p_end}
{synopt:{opt cl:eargraphs}} suppress storing of graphs in Stata memory {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_dif} is a postestimation command of {helpb uirt}
that allows for differential item functioning (DIF) analysis after a two-group model was fit.
For each item specified for DIF analysis a two-group model with common item parameters in both groups
is compared against a model with group-specific parameters for that item.
Statistical significance of DIF is verified by a LR test.
Effect measures are computed on the observed score metric (P-DIF) by subtracting expected mean scores of an item
under each of the group-specific item parameter estimates (Wainer, 1993).
Namely, P-DIF|GR=E(parR,GR)-E(parF,GR), where GR indicates that the reference group distribution was used for integration
and parR and parF stand for item parameters estimated in GR and GF respectively. Analogous P-DIF|GF measure is also computed.
DIF significance and effect size information is stored in {cmd:r(dif_results)}. 
Group-specific item parameter estimates are stored in {cmd:r(dif_item_par_GR)} and {cmd:r(dif_item_par_GF)}.
Using {cmd:uirt_dif} in estimation mode will also result in plotting graphs with group-specific ICCs and PDFs, which are saved in the working directory.


{marker options}{...}
{title:Options}

{phang}
{opt f:ormat(str)} specifies the file format in which the DIF graphs are saved (png|gph|eps).
Default value is format(png).

{phang}
{opt c:olors(str)} is used to override default color codes used for group-specific ICC and PDF lines. 
By default, the plots in the reference group are {it:red}, and the plots in the focal group are {it:blue}.
It requires a pair of color names separated by spaces.
The first color applies to the reference group, the second applies to the focal group.

{phang}
{opth tw(twoway_options)} it is used to add user-defined twoway graph options to override the default graph layout,
like: {opt xtitle()} or {opt scheme()} etc.

{phang}
{opt cl:eargraphs} is used to suppress the dafault behaviour of storing all DIF graphs in Stata memory. 
After specifying this, all graphs are still saved in the current working directory, but only the last graph is active in Stata. 


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Fit a 2-group IRT model with default settings of {helpb uirt} using items q1-q9 and {it:female} variable for grouping {p_end}
{phang2}{cmd:. uirt q*,gr(female)} {p_end}

{pstd}Analyze DIF only for item q1{p_end}
{phang2}{cmd:. uirt_dif q1} {p_end}

{pstd}Perform DIF analysis for all items, change graph scheme and group-specific coloring of plots {p_end}
{phang2}{cmd:. uirt_dif *, tw(scheme(sj)) c(gs2 gs6)} {p_end}



{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_dif} stores the following in r():}

{p2col 3 32 34 4:Matrices} {p_end}
{p2col 3 32 34 4:{cmd:r(dif_results)}}LR test results and effect size measures after DIF analysis{p_end}
{p2col 3 32 34 4:{cmd:r(dif_item_par_GR)}}parameters of DIF items obtained in the reference group{p_end}
{p2col 3 32 34 4:{cmd:r(dif_item_par_GF)}}parameters of DIF items obtained in the focal group{p_end}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com


{marker references}{...}
{title:References}

{phang}
Wainer, H. 1993.
Model-Based Standardized Measurement of an Item's Differential Impact. 
In: {it:Differential Item Functioning.}
ed. Holland, P. W. & Wainer, H., 123{c -}136.
Hillsdale: Lawrence Erlbaum.

