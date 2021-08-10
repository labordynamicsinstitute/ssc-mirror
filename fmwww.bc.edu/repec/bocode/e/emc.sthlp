{smcl}
{* *! version 1.0 13 Nov 2017}{...}
{viewerjumpto "Syntax" "emc##syntax"}{...}
{viewerjumpto "Description" "emc##description"}{...}
{viewerjumpto "Examples" "emc##examples"}{...}
{viewerjumpto "Stored results" "emc##results"}{...}
{viewerjumpto "References" "emc##references"}{...}
{viewerjumpto "Author and support" "emc##author"}{...}
{title:Title}

{phang}
{bf:emc} - Effect modifier on contrasts - Prefix command estimating effect 
measure values (contrasts) and their confidence interval for a set of 
effect modifier values.

{marker syntax}{...}
{title:Syntax}

{p 8 20}
{cmdab:emc, }{it:mandatory_options}
[{it:optional_options twoway_options}]{cmd::} regression command

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Mandatory}
{synopt:{opt at(numlist)}}A numlist of length greater than 1. The values of 
the effect modifier at which to estimate the effect measure. Mandatory.{p_end}

{syntab:Optional}
{synopt:{opt p:ctknots(numlist)}} A numlist of values between 0 and 100. 
The length of the numlist must be between 3 and 10. 
They specify the percentages of the percentiles that are used for calculating 
the restricted cubic splines.{p_end}

{synopt:{opt n:knots(#)}} Integer value between 3 and 7 specifying recommended 
standard set of percentages, described in [opt nknots} in 
{mansection R mksplineMethodsandformulas: {cmd:mkspline}, Methods and formulas}. 
Default value is 4. If option {opt p:ctknots} is set, option {opt n:knots} is 
ignored.{p_end}

{synopt:{opt K:eepcubicsplines}} Keep the generated cubic spline regressors for 
detailed analysis.{p_end}

{synopt:{opt e:form}} Exponentiate the estimated effect measures.{p_end}

{synopt:{opt emcnames(namelist)}} Rename the generated variables 
with the requested values of the effect modifier, the estimated effect measures
and the 95% CI for the estimated effect measure. Must have length 4.
Default names are "__third_variable_name", "__third_variable_name_contrast",
"__third_variable_name_lb" and "__third_variable_name_ub"{p_end}

{synopt:{opt ci:limits(numlist)}} A numlist of length 1. A real between 0 
and 100. Option to change the percentage for the confidence intervals from the
default 95 (%).{p_end}

{synopt:{opt gr:aph}} Generate a default graph.{p_end}

{synopt:{opt twoway options:}} Generate a default graph with the twoway options.
Option {opt gr:aph} is not necessary in this case.{p_end}
{synoptline}

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
The prefix command {cmd:emc} takes a regression command as an argument. 
From the regression command argument {cmd:emc} uses the first variable as an 
outcome variable, the second as a dichotomous contrast variable and the third 
as effect modifier transformed into a function using cubic splines.

{pstd}
For each value in the numlist specified in the {opt at:} option, the estimated 
contrast and the confidence interval limits (normal approximation) are saved in 
four variables. 
For reproducibility, detailed results are stored in the returned values.

{pstd}
A simple default graph of the estimates and the 95% confidence interval 
are generated by the option {opt gr:aph}. 
It is deliberately simple but easily modifiable by any {cmd:twoway} option.
if any {cmd:twoway} option is set the the option {opt gr:aph} is not necessary.

{pstd}
The calculations in prefix command {cmd:emc} are based on returned matrices e(b) 
and e(V) and are therefore independent of the type of regression performed. 
Interesting contrasts (directly or exponentiated) that may be studied with this 
approach include:

{pstd}
* difference in means using -regress- or -mixed-{break}
* odds ratios using -logit- or -logistic-{break}
* odds ratios in a matched study using -clogit-{break}
* risk differences using -binreg-{break}
* relative risks using -binreg-{break}
* hazard ratios using -stcox-{break}
* incidence rate ratios using -poisson- or -nbreg-{break}

{pstd}
Contrasts in -glm- are also possible to analyse.

{pstd}
The author developed this command to estimate and visualise effect modification 
on a contrast or the log of the contrast.
However, the command can also be used to visualise gap developments by a 
continuous variable e.g. visualising the income gap over time between the 
two genders.

{marker examples}{...}
{title:Examples}

{pstd}Data are described in {browse "http://biostat.mc.vanderbilt.edu/dupontwd/wddtext":Statistical Modeling for Biomedical Researchers}.{p_end}
{phang}The book is a very good reference.{p_end}

{pstd}{bf:Click once on the commands (blue text) below to perform these in Stata.}{p_end}
{phang}Retrieve data{p_end}
{phang}. {stata `"use "http://biostat.mc.vanderbilt.edu/dupontwd/wddtext/data/1.4.11.Sepsis.dta", clear"'}{p_end}

{phang}Use the {cmd:emc} prefix command to estimate the risk at apache scores 
from 0(5)40 and generate the default graph named contrast{p_end}
{phang}. {stata `"emc, at(0(5)40) name(contrast, replace): binreg fate treat apache, rd"'}{p_end}

{phang}The knots for unexposed(E0) and exposed(E1) are quite similar{p_end}
{phang}. {stata `"matlist r(knots)"'}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:emc} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 4 20 19 2: Macros}{p_end}
{synopt:{cmd:r(graph_cmd)}}The {help twoway:twoway} graph command generating the graph.{p_end}
{synopt:{cmd:r(emnames)}}The names of the variables generated.{p_end}
{synopt:{cmd:r(command)}}The regression command generating the estimates.{p_end}

{p2col 4 20 19 2: Matrices}{p_end}
{synopt:{cmd:r(predictions)}}Predicted unexposed, predicted exposed and 
predicted contrast as well as their confidence intervals.{p_end}
{synopt:{cmd:r(regressors)}}Regressors used for the predictions.{p_end}
{synopt:{cmd:r(knots)}}The knots used for the unexposed and exposed parts 
of the second risk factor.{p_end}

{marker references}{...}
{title:References}

{pstd}{browse `"https://www.stata.com/meeting/nordic-and-baltic19/slides/nordic19_bruun.pdf"': Presentation at 2019 Nordic and Baltic Stata Users Group meeting}

{pstd}{browse `"https://www.stata-journal.com/article.html?article=st0567"': Bruun (2019), Visualizing effect modification on contrasts. Stata Journal.}

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
