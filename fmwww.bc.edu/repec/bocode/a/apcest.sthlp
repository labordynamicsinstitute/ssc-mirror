{smcl}
{* *! version 2.0 ||23.7.2026 || Gordey Yastrebov}{...}
{hi:help apcest}{...}
{right:also see: {helpb apcdescribe}, {helpb apcbound}, {helpb apcplot}}
{hline}


{title:Title}

{pstd} {hi:apcest} {hline 2} An estimation wrapper command to facilitate the Fosse-Winship bounding approach to APC analysis (part of the {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcest}, {help apcest##options:{it:effect_specifications}} {cmd::} {it:estimation_command}

{pstd}where {it:estimation_command} is a regular Stata estimation command
(e.g., {cmd:regress y x1 x2 x3 x4 if sample == 1 [aweight = weight], vce(cluster id)}),
and {help apcest##options:{it:effect_specifications}} designates the APC variables and
their effect specifications (see below). An {it:estimation_command} must not include
APC effects as {help apcest##options:{it:effect_specifications}} makes this
redundant, i.e., apart from the dependent variable, it should only specify control variables.


{title:Description}

{pstd}{cmd:apcest} is a wrapper command for estimating APC models. It saves
the linear and the nonlinear components of APC effects to be processed
later in postestimation with the {helpb apcbound} and {helpb apcplot} commands
of the {cmd:apcbound} package.


{marker options}{title:Effect specifications}

{pstd}Options {opt a(specification)}, {opt p(specification)}, and {opt c(specification)} are
all mandatory and designate the respective APC variables in the dataset and their effect specifications.

{pstd}If {it:spec} only contains a variable name (e.g., {cmd:a(age)}),
a respective APC effect is assumed to be just linear and thus to consist of
only the linear component. Otherwise a variable name must be followed
by a nonlinear specification. Currently three different options for
specifying nonlinearities are possible:

{pstd}1) If {it:specification} = {bf:varname^#} (e.g., {cmd:a(age^4)}) a polynomial
specification for variable {bf:varname} will be assumed, where # is an
integer that sets the order of the polynomial.

{pstd}2) If {it:specification} = {bf:i.varname} (e.g., {cmd:p(i.period)}), a variable
{bf:varname} will be treated as categorical. Regular Stata {help fvvarlist##bases:syntax} for specifying reference categories is also possible here.

{pstd}3) If {it:specification} = {bf:varname}:{it:{help numlist}} (e.g.,
{cmd:c(cohort:1900(10)2000)}), the values of a variable {bf:varname} will 
be grouped as per {cmd:cut(varname)} in Stata's {bf:{help egen}} command with the option {bf:at(}{it:{help numlist}{bf:)}}. The grouped values are saved in the corresponding generated APC estimation variable
({bf:__apcest_a}, {bf:__apcest_p}, or {bf:__apcest_c}); the original variable
{bf:varname} is left intact. A reference will be assigned automatically as one
of the middle categories.

{pstd}For all continuous specifications, {cmd:apcest} creates copies
named {bf:__apcest_a}, {bf:__apcest_p}, and {bf:__apcest_c} and mean-centers
these estimation variables prior to model estimation. The original APC variables
are not modified. Mean-centering is taken into account in the rendering of APC
effects by {cmd:apcplot}.

{pstd}{bf:Important notice:} All source APC variables specified with {it:varname},
regardless of whether they are specified as continuous or categorical, must have
consistent scales. The most straightforward example of scale consistency is when all
variables are measured in years (e.g., {it:35} for {bf:age}, {it:2001} for {bf:period},
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
{bf:race} as a control, {it:age} effect specified using second-order
polynomial terms, {it:period} effect specified using single-year dummies, and {it:cohort} effect
specified using a simple linear term:

	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): regress ln_wage i.race"}

{pstd}Same as above, except grouping {it:period} into five-year intervals using a
{it:numlist}. The grouped values are stored in {bf:__apcest_p}, while the original
{bf:year} variable remains unchanged:

	. {stata "apcest, a(age^2) p(year:68(5)93) c(birth_yr): regress ln_wage i.race"}

{pstd}Same as the first model, except estimating a logistic regression with a binary {bf:msp}
variable on a subset of observations, and asking the estimation command to return odds
ratios instead of regular logits:

	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): logit msp i.race if age > 25, or"}

{pstd}An example with random-effects panel estimation:

	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): xtreg ln_wage i.race, re"}

{pstd}An example with mixed model estimation:

	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): mixed ln_wage i.race || idcode:"}


{title:Stored results}

{pstd}{cmd:apcest} leaves the wrapped estimation command's results active and stores
a copy under the name {bf:__apcestimates}. This stored estimate is used by
{helpb apcbound} and {helpb apcplot} in postestimation.

{pstd}Each call first drops any existing variables with the following names and then
creates them in the currently active dataset: {bf:__apcest_esample} identifies the estimation sample (1 for observations in the sample and 0 otherwise), {bf:__apcest_a}, {bf:__apcest_p}, and {bf:__apcest_c} for each of the APC estimation variables.

{pstd}The three APC estimation variables contain copies or transformations of the
source APC variables according to their effect specifications. Continuous variables
are mean-centered; variables specified with factor-variable notation are copied;
and variables specified with {it:varname}:{it:numlist} contain the grouped values
created by {cmd:egen, cut()}. These four variables remain in the active dataset after
estimation and are replaced the next time {cmd:apcest} is run.


{title:Author}

{p 4} {cmd:Gordey Yastrebov} {p_end}
{p 4} {it:University of Cologne} {p_end}
{p 4} {browse "mailto:gordey.yastrebov@gmail.com":gordey.yastrebov@gmail.com} {p_end}


{title:Citation}

{pstd}
When referring to {cmd:apcbound}, {cmd:apcest}, {cmd:apcplot}, or
{cmd:apcdescribe} in published work, please consider citing the software package
and the article implementing the bounding approach:
{p_end}

{phang}
{cmd:Yastrebov, G.} (2026). "APCBOUND: Stata module for the Fosse-Winship bounding
approach to age-period-cohort analysis (Version 2.0)" [Computer software].
Boston College Department of Economics, Statistical Software Components.
{browse "https://ideas.repec.org/c/boc/bocode/s459449.html":https://ideas.repec.org/c/boc/bocode/s459449.html}
{p_end}

{phang}
{cmd:Yastrebov, G., Trinidad, A., and Leopold, T.} (2025). A Bounding Approach to Age-Period-Cohort Analysis: A Demonstration Using Public Crime Concerns in Germany. {it:Journal of Quantitative Criminology}.
{browse "https://doi.org/10.1007/s10940-025-09633-7":https://doi.org/10.1007/s10940-025-09633-7}
{p_end}
