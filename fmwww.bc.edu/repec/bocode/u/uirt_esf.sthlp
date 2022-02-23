{smcl}
{* *! version 1.0 2022.02.09}{...}
{viewerjumpto "Syntax" "uirt_esf##syntax"}{...}
{viewerjumpto "Description" "uirt_esf##description"}{...}
{viewerjumpto "Options" "uirt_esf##options"}{...}
{viewerjumpto "Examples" "uirt_esf##examples"}{...}
{viewerjumpto "Stored results" "uirt_esf##results"}{...}
{cmd:help uirt_esf}
{hline}

{title:Title}

{phang}
{bf:uirt_esf} {hline 2} Postestimation command of {helpb uirt} to plot expected score functions for items and expected sum-score function for a set of items

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_esf} [{varlist}] [{cmd:,}{it:{help uirt_esf##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run. 
If {it:varlist} is skipped or asterisk * is used and no options are added,
{cmd:uirt_esf} will create IESF plots for all items declared in main list of items of current {cmd:uirt} run. 

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt tesf}} draws expected sum-score function (test characteristic curve) instead of IESF {p_end}
{synopt:{opt all}} creates both IESF and TESF graphs  {p_end}
{synopt:{opt bins(#)}} number of ability intervals for observed mean scores; default: bins(100) {p_end}
{synopt:{opt noo:bs}} suppress plotting observed mean scores{p_end}
{synopt:{opt c:olor(str)}} color name to override default color of ESF lines and markers {p_end}
{synopt:{opth tw(twoway_options)}} twoway graph options to override default graph layout {p_end}
{synopt:{opt f:ormat(str)}} file format for ESF graphs (png|gph|eps); default: format(png) {p_end}
{synopt:{opt pref:ix(str)}} set the prefix of file names {p_end}
{synopt:{opt suf:fix(str)}} set the suffix of file names {p_end}
{synopt:{opt cl:eargraphs}} suppress storing of graphs in Stata memory {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_esf} is a postestimation command of {helpb uirt}.
It allows to plot the expected score functions of individual items (IESF) 
or the expected sum-score function of a test consisting of items provided in {it:varlist} (TESF).  
On an item level it is similar to {helpb uirt_icc}. 
The difference is that {cmd:uirt_icc} draws probabilities of each response-category against theta, 
whereas {cmd:uirt_esf} plots the expected item score against theta. 
For binary items ICC and IESF are the same (only range of y-axis may be different, if item is not coded 0-1).
IESF becomes useful to analyze psychometric properties of polytomous items. Especially, when there are many response categories 
(single curve characterizes performance of the item) or when numerical values of response categories are not equally spaced.
The test-level expected sum-score (TESF) is obtained with the {opt tesf} option. TESF is also called test characteristic curve (TCC).

{pstd}
Default behavior of {cmd:uirt_esf} is to superimpose means of observed scores against the estimated expected response curves. 
This aids graphical assessment of model fit.
The observed mean scores are computed after quantile-based division of the distribution of latent variable, analogously as in {helpb uirt_icc}.
Plotting observed mean scores is controlled by {opt bins()}, it can be also turned off by {opt noobs}. 
Default look of graphs can be overridden by options: {opt c:olor()} and {opt tw()}.

{pstd}
Note that if ESF graphs for requested items are already saved in the working directory under default names, they will be overwritten after the command is repeated.
If you do not want to overwrite previous files, change the working directory, rename the existing files, or use {opt pref:ix(str)} or {opt suf:fix(str)} options.


{marker options}{...}
{title:Options}

{phang}
{opt tesf} creates a plot with the expected sum-score function of a test consisting of items provided in the {it:varlist}. 
Such a plot is described with an acronym TESF in this help file, but it is also known as TCC (Test Characteristic Curve).

{pmore}
{cmd:uirt_esf} adds observed mean scores to all plots by default. 
Note, that in case of TESF it is achieved by summation of the observed mean scores of individual items.
Even if the number of observations differ between items in your data (incomplete designs, missing data), 
each item will be included with equal weight in the sum-score.

{phang}
{opt all} results in plotting both the item-level IESF graphs, and the test-level TESF graph.

{phang}
{opt bins(#)} sets the number of intervals the distribution of ability is split into
when calculating observed mean scores. Default value is bins(100).

{phang}
{opt noo:bs} suppresses plotting observed proportions.

{phang}
{opt c:olor(str)} is used to override the default color ({it:green}) that is used for both the RF lines and the observed score markers.

{phang}
{opth tw(twoway_options)} it is used to add user-defined twoway graph options to override the default graph layout,
like: {opt xtitle()} or {opt scheme()} etc.

{phang}
{opt f:ormat(str)} specifies the file format in which the RF graphs are saved (png|gph|eps).
Default value is format(png).

{phang}
{opt pref:ix(str)} is used to define a string that is added at the beginning of the names of saved files.
Default value for the item response functions is is prefix(esf). The test response function has no default prefix.

{phang}
{opt suf:fix(str)} adds a user-defined string at the end of the names of saved files.
Default behavior is not to add any suffix.

{phang}
{opt cl:eargraphs} is used to suppress the default behavior of storing all ICC graphs in Stata memory. 
After specifying this, all graphs are still saved in the current working directory, but only the last graph is active in Stata. 


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc1} {p_end}
{phang2}{cmd:. gen s_q8q9 = q8 + q9} {p_end}

{pstd}Fit an IRT model to binary items q1-q7 and the artificial 3-categorical item s_q8q9 with {helpb uirt}; create ICC plot for s_q8q9 with {helpb uirt_icc}{p_end}
{phang2}{cmd:. uirt q1-q7 s_q8q9} {p_end}
{phang2}{cmd:. uirt_icc s_q8q9, tw(title(Item s_q8q9: ICC plot))} {p_end}

{pstd}Create IESF plot for s_q8q9, and combine the two graphs to compare information from ICC and IESF {p_end}
{phang2}{cmd:. uirt_esf s_q8q9, tw(title("Item s_q8q9: IESF plot"))} {p_end}
{phang2}{cmd:. gr combine ICC_s_q8q9 IESF_s_q8q9} {p_end}

{pstd}Create TESF plot for all items used in the current {helpb uirt} run {p_end}
{phang2}{cmd:. uirt_esf *, tesf} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_esf} does not store anything in r():}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com

