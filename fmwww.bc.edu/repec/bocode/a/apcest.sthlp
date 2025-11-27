{smcl}
{* *! version 1.3 || 25.11.2025 || Gordey Yastrebov}{...}
{hi:help apcest}{...}
{right:also see: {helpb apcbound}, {helpb apcplot}}
{hline}


{title:Title}

{pstd} {hi:apcest} {hline 2} An estimation wrapper command to facilitate Fosse-Winship bounding approach to APC analysis (part of {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcest} {it:estimation_command}, {help apcest##options:{it:effect_specifications}} {it:estimation_command_options}

{pstd}where {it:estimation_command} is a regular Stata estimation command 
(e.g., {cmd:regress y x1 x2 x3 x4 if sample == 1 [aweight = weight]}), {help apcest##options:{it:effect_specifications}} designates the APC variables and 
their effect specifications (see below), and {it:estimation_command_options} 
is the estimation command's options typically specified after a comma 
(e.g., {opt vce(cluster id)}). An {it:estimation_command} must not include
APC effects as {help apcest##options:{it:effect_specifications}} makes this 
redundant, i.e., it should only specify the control variables.


{title:Description}

{pstd}{cmd:apcest} is a wrapper command for estimating APC models. It saves 
the linear and the nonlinear components of APC effects to be processed
later in post-estimation with {helpb apcbound} and {helpb apcplot} commands 
of the {cmd:apcbound} package.


{marker options}{title:Effect specifications}

{pstd}Options {opt a(spec)}, {opt p(spec)}, and {opt c(spec)} are
all mandatory and designate respective APC variables in the dataset and their effect specifications.

{pstd}If {it:spec} only contains a variable name (e.g., {opt a(age)}), 
a respective APC effect is assumed to be just linear and thus to consist of 
only the linear component. Otherwise a variable name must be followed 
by a nonlinear specification. Currently three different options for 
specifying nonlinearities are possible:

{pstd}1) If {it:spec} = {it:varname^#} (e.g., {opt a(age^4)}) a polynomial
specification for variable {it:varname} will be assumed, where # is an 
integer that sets the order of the polynomial.

{pstd}2) If {it:spec} = {it:i.varname} (e.g., {opt p(i.period)}), a variable
{it:varname} will be treated as categorical. Regular Stata {help fvvarlist##bases:syntax} 
for specifying reference categories is also possible here.

{pstd}3) If {it:spec} = {it:varname}:{it:numlist} (e.g., {opt c}({it:cohort}:{it:1900(10)2000}), 
a variable {it:varname} will be sliced as per {opt cut(varname)} in Stata's {cmd:egen} 
command with the option {opt at(numlist)}. A sliced variable will be temporary and it will be dropped after estimation, leaving the original variable {it:varname} intact. A reference will be assigned
automatically as one of the middle categories.

{pstd}{bf:All} continuous APC variables will be automatically mean-centered prior to model 
estimation and restored to their original scales afterward. Mean-centering is taken into 
account in the rendering of APC effects by {cmd:apcplot}.

{pstd}{bf:Important notice:} All source APC variables specified with {it:varname}, 
regardless of whether they are specified as continuous or categorical, must have 
consistent scales. A most straightforward example of scale consistency is when all 
variables are measured in years (e.g., {it:35} for {bf:age}, {it:2001} for {bf:period} 
and {it:1983} for {bf:cohort}). This is because scale consistency is an important 
assumption for modelling APC effects and, in particular, deducing their linear 
components. One must be particularly careful with categorical APC variables,
the values of which might not exactly match the distances between categories 
(e.g., when {bf:1} is for cohorts "1930-1932", {bf:2} is for cohorts "1933-1941", etc.),
in which case it is advisable to recode their values to represent distances between
average interval values in the scales characteristic of the other APC variables 
(e.g., {bf:1} to become 1931 and {bf:2} to become 1937, when {bf:age} and {bf:period} 
are measured in years).


{title:Examples}

{pstd}Load sample data:

	. {stata webuse nlswork, clear}

{pstd}Estimate a simple OLS model with {bf:ln_wage} as a dependent variable,
{bf:race} as a control, {it:age} effect specified using 2nd order 
polynomial terms, {it:period} effect specified using single-year dummies, and {it:cohort} effect
specified using a simple linear term:

	. {stata apcest regress ln_wage i.race, a(age^2) p(i.year) c(birth_yr)}

{pstd}Same as above, except estimating a logistic regression with a binary {bf:msp} 
variable on a subset of observations, and asking the estimation command to return odds 
ratios instead of regular logits:

	. {stata apcest logit msp i.race if age > 25, a(age^2) p(i.year) c(birth_yr) or}

{pstd}An example with mixed model estimation:

	. {stata "apcest mixed ln_wage i.race || idcode:, a(age^2) p(i.year) c(birth_yr)"}


{title:Stored results}

{pstd}{cmd:apcest} stores all estimation results in a container called {bf:__apcest}, 
from which {helpb apcbound} and {helpb apcplot} commands will extract all relevant
information in postestimation. It also creates {bf:__apcsample} variable in the currently
active dataset to identify the estimation sample (used by {cmd:apcplot}), analogous to {helpb estimates store} command.


{title:Author}

{p 4} {cmd:Gordey Yastrebov} {p_end}
{p 4} {it:University of Cologne} {p_end}
{p 4} {browse "mailto:gordey.yastrebov@gmail.com":gordey.yastrebov@gmail.com} {p_end}
