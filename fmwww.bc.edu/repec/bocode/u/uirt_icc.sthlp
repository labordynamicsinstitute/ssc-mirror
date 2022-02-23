{smcl}
{* *! version 1.1 2022.01.24}{...}
{viewerjumpto "Syntax" "uirt_icc##syntax"}{...}
{viewerjumpto "Description" "uirt_icc##description"}{...}
{viewerjumpto "Options" "uirt_icc##options"}{...}
{viewerjumpto "Examples" "uirt_icc##examples"}{...}
{viewerjumpto "Stored results" "uirt_icc##results"}{...}
{cmd:help uirt_icc}
{hline}

{title:Title}

{phang}
{bf:uirt_icc} {hline 2} Postestimation command of {helpb uirt} to create ICC plots and perform graphical item-fit analysis

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_icc} [{varlist}] [{cmd:,}{it:{help uirt_icc##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run. 
If {it:varlist} is skipped or asterisk * is used, {cmd:uirt_icc} will plot ICC graphs for all items declared in main list of items of current {cmd:uirt} run. 

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt bins(#)}} number of ability intervals for observed proportions; default: bins(100) {p_end}
{synopt:{opt noo:bs}} suppress plotting observed proportions{p_end}
{synopt:{opt pv}} use plausible values to compute observed proportions; default is to use numerical integration {p_end}
{synopt:{opt pvbin(#)}} number of plausible values in each bin; default: pvbin(10000) {p_end}
{synopt:{opt c:olors(str)}} list of colors to override default colors of ICC lines {p_end}
{synopt:{opth tw(twoway_options)}} twoway graph options to override default graph layout {p_end}
{synopt:{opt f:ormat(str)}} file format for ICC graphs (png|gph|eps); default: format(png) {p_end}
{synopt:{opt pref:ix(str)}} set the prefix of file names {p_end}
{synopt:{opt suf:fix(str)}} set the suffix of file names {p_end}
{synopt:{opt cl:eargraphs}} suppress storing of graphs in Stata memory {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_icc} is a postestimation command of {helpb uirt} that creates ICC graphs accompanied with information that aides graphical item-fit analysis.
The graphs are saved in current working directory. 
Note that if ICC graphs for requested items are already saved in the working directory under default names, they will be overwritten.
If you do not want to overwrite previous ICCs, change the working directory, rename the existing files, or use {opt pref:ix(str)} or {opt suf:fix(str)} options.

{pstd}
Default behavior of {cmd:uirt_icc} is to superimpose observed proportions against the ICC curves in order to enable a graphical item-fit assessment.
The observed proportions are computed after quantile-based division of the distribution of latent variable.
Item response of a single person is included simultaneously into many intervals (bins) of theta with probability
proportional to the density of {it: a posteriori} latent trait distribution of that person in each bin.
Default method uses definite numerical integration, but after adding option {opt pv}, plausible values (PVs) will be employed to achieve this task.
Plotting observed proportions is controlled by {opt bins()} and {opt pvbin()}, it can be also turned off by {opt noobs}. 
Default look of graphs can be overriden by options: {opt c:olors()} and {opt tw()}.


{marker options}{...}
{title:Options}

{phang}
{opt bins(#)} sets the number of intervals the distribution of ability is split into
when calculating observed proportions of responses. Default value is bins(100).

{phang}
{opt pv} changes the default method of computing observed proportions from definite numerical integration to Monte Carlo integration
with unconditioned PVs. It involves more CPU time, introduces variance due to sampling of PVs, 
but takes the uncertainty in estimation of IRT model parameters into account.

{phang}
{opt pvbin(#)} sets the number of plausible values used for computing observed proportions of responses
within each interval of theta. Default value is pvbin(10000).

{phang}
{opt noo:bs} suppresses plotting observed proportions.

{phang}
{opt c:olors(str)} is used to override the default Munsell color system used for ICC lines.
It requires a list of color names separated by spaces.
The first color in the list applies to the pseudo-guessing parameter of 3PLM - it must be declared even if there are no 3PLM items in the model.

{phang}
{opth tw(twoway_options)} it is used to add user-defined twoway graph options to override the default graph layout,
like: {opt xtitle()} or {opt scheme()} etc.

{phang}
{opt f:ormat(str)} specifies the file format in which the ICC graphs are saved (png|gph|eps).
Default value is format(png).
This option influences also the graphs created after asking for DIF analysis.

{phang}
{opt pref:ix(str)} is used to define a string that is added at the beginning of the names of saved files.
Default value is prefix(ICC).

{phang}
{opt suf:fix(str)} adds a user-defined string at the end of the names of saved files.
Default behavior is not to add any suffix.

{phang}
{opt cl:eargraphs} is used to suppress the dafault behaviour of storing all ICC graphs in Stata memory. 
After specifying this, all graphs are still saved in the current working directory, but only the last graph is active in Stata. 


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc1} {p_end}

{pstd}Fit an IRT model using all items in the dataset with default settings of {helpb uirt}{p_end}
{phang2}{cmd:. uirt q*} {p_end}

{pstd}create ICC graphs for all items used in the above command - these will be stored as PNG files in current working direcrory{p_end}
{phang2}{cmd:. uirt_icc} {p_end}

{pstd}create ICC graph only for item q1, change graph title, the name of x-axis, and the color of the ICC line, add suffix "xx" at the end of file name{p_end}
{phang2}{cmd:. uirt_icc q1,tw(title(ICC graph for item 1) xtitle(My preferred name for {&theta} variable)) color(any_for_c green) suff(xx)} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_icc} does not store anything in r():}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com

