{smcl}
{* *! version 1.0 2022.02.11}{...}
{viewerjumpto "Syntax" "uirt_inf##syntax"}{...}
{viewerjumpto "Description" "uirt_inf##description"}{...}
{viewerjumpto "Options" "uirt_inf##options"}{...}
{viewerjumpto "Examples" "uirt_inf##examples"}{...}
{viewerjumpto "Stored results" "uirt_inf##results"}{...}
{cmd:help uirt_inf}
{hline}

{title:Title}

{phang}
{bf:uirt_inf} {hline 2} Postestimation command of {helpb uirt} to plot information functions

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_inf} [{varlist}] [{cmd:,}{it:{help uirt_inf##options:options}}]

{pmore}
{it:varlist} must include only variables that were declared in the main list of items of current {cmd:uirt} run. 
If {it:varlist} is skipped or asterisk * is used and no options are added, {cmd:uirt_inf} will create a graph with item information functions
for all items declared in main list of items of current {cmd:uirt} run. 

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt t:est}} test-level I(theta) {p_end}
{synopt:{opt se}} conditional standard error, instead of I(theta); only with {opt t:est}  {p_end}
{synopt:{opt gr:oups}} group-specific I(theta); only with {opt t:est} and a multi-group model  {p_end}
{synopt:{opth tw(twoway_options)}} twoway graph options to override default graph layout {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_inf} is a postestimation command of {helpb uirt}.
It allows to plot the information functions of individual items
or the information function of a test consisting of items provided in {it:varlist}.
Test information function is obtained with {opt t:est} option. It is equal to the sum of individual item information functions 
and a term that accounts for the prior distribution of theta (reciprocal of the variance of the prior). 
In a multi-group model, this may result in different shapes of test information functions for each group. 
By default {cmd:uirt_inf} will plot the test information function only for the reference group.
If you wish to see the group-specific I(theta) plots, you should add the {opt gr:oups} option.
When {opt t:est} is used together with {opt se}, a function of standard error of the estimate of theta is plotted instead of the default I(theta).
It is equal to the reciprocal of the square root of test information function. 
Group-specific standard error plots in multi-group models can be obtained by adding the {opt gr:oups} option.

{marker options}{...}
{title:Options}

{phang}
{opt t:est} creates a graph with test information function for items specified in {it:varlist}.
It can be modified with {opt se} to produce standard error plot.
In multi-group models, it can be also modified with {opt gr:oups} to produce group-specific plots.

{phang}
{cmd:se} modifies the {opt t:est} option, to produce a plot with standard error of theta estimates. 
In multi-group models, it can be also modified with {opt gr:oups} to include group-specific plots.

{phang}
{opt gr:oups} modifies the test-level graphs to include group-specific plots. 
It will take no effect in a single-group model, or if option {opt t:est} is not included.

{phang}
{opth tw(twoway_options)} it is used to add user-defined twoway graph options to override the default graph layout,
like: {opt xtitle()} or {opt scheme()} etc.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Fit a two-group IRT model with {helpb uirt}{p_end}
{phang2}{cmd:. uirt q*,gr(female)} {p_end}

{pstd}Item information function for q1{p_end}
{phang2}{cmd:. uirt_inf q1} {p_end}

{pstd}Item information functions for all items{p_end}
{phang2}{cmd:. uirt_inf} {p_end}

{pstd}Test information function assuming all items{p_end}
{phang2}{cmd:. uirt_inf *, test} {p_end}

{pstd}Group-specific test information functions{p_end}
{phang2}{cmd:. uirt_inf *, test gr} {p_end}

{pstd}Create a graph with group-specific standard error functions, name it for use in next step{p_end}
{phang2}{cmd:. uirt_inf *, test se gr tw(name(se_theta_inf))} {p_end}

{pstd} Add the EAP estimate and its standard error to the dataset with {helpb uirt_theta};
 create a scatterplot of SE(EAP) and EAP; combine with the graph from previous step to compare the results{p_end}
{phang2}{cmd:. uirt_theta ,eap} {p_end}
{phang2}{cmd:. tw (scatter se_theta theta if female==0,yvarlab(female=0) ) || (scatter se_theta theta if female==1,yvarlab(female=1)),  xscale(range(-4 4)) name(se_theta_eap) ytitle(Standard error of EAP) xtitle(EAP of theta) title (EAP - error vs estimates)} {p_end}
{phang2}{cmd:. gr combine se_theta_eap  se_theta_inf, ycommon} {p_end}



{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_inf} does not store anything in r():}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com

