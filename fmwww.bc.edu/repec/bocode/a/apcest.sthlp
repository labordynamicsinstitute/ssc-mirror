{smcl}
{* *! version 2.2 || 16.9.2026 || Gordey Yastrebov}{...}
{hi:help apcest}{...}
{right:also see: {helpb apcdescribe}, {helpb apcbound}, {helpb apcplot}}
{hline}


{title:Title}

{pstd} {hi:apcest} {hline 2} An estimation wrapper command to facilitate the Fosse-Winship bounding approach to APC analysis (part of the {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcest}, {help apcest##options:{it:effect_specifications}}{cmd::} {it:estimation_command}

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
{bf:varname} will be treated as categorical. The categorical nonlinear representation is 
stored in a dedicated newly created variable (see below). Regular 
Stata {help fvvarlist##bases:syntax} for specifying reference categories is also possible here.

{pstd}3) If {it:specification} = {bf:varname}:{it:{help numlist}} (e.g.,
{cmd:c(cohort:1900(10)2000)}), the values of variable {bf:varname} will
be grouped as per {cmd:cut(varname)} in Stata's {bf:{help egen}} command with
the option {bf:at(}{it:{help numlist}{bf:)}}. The grouped nonlinear representation
is saved in a dedicated newly created variable (see below). A reference will
be assigned automatically as one of the middle categories.

{pstd}Irrespective of the nonlinear specification, {cmd:apcest} creates
{bf:__apcest_A}, {bf:__apcest_P}, and {bf:__apcest_C} from the original numerical
age, period, and cohort variables and mean-centers them on the common estimation
sample. These variables carry the linear APC components. Categorical and grouped
nonlinear representations are kept separately in {bf:__apcest_nlA},
{bf:__apcest_nlP}, and {bf:__apcest_nlC}; polynomial terms are constructed from
the corresponding centered linear variable. The original APC variables are not modified.

{pstd}{bf:Important notice:} The source APC variables must be on a common numerical
scale and satisfy the linear APC identity {bf:period = age + cohort} on the estimation
sample (up to numerical precision). Grouping or treating an APC variable as categorical
changes only its nonlinear representation and does not relax this requirement. The
most straightforward specification uses all three variables in the same time units
(e.g., years).


{title:Examples}

{pstd}Load sample data:

	. {stata webuse nlswork, clear}

{pstd}Estimate a simple OLS model with {bf:ln_wage} as a dependent variable,
{bf:race} as a control, {it:age} effect specified using second-order
polynomial terms, {it:period} effect specified using single-year dummies, and {it:cohort} effect
specified using a simple linear term:

	. {stata "apcest, a(age^2) p(i.year) c(birth_yr): regress ln_wage i.race"}

{pstd}Same as above, except grouping {it:period} into five-year intervals using a
{it:numlist}:

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

{pstd}Each call first drops any existing APCEST working variables and then creates
{bf:__apcest_esample}, which identifies the estimation sample (1 for observations
in the sample and 0 otherwise), and {bf:__apcest_A}, {bf:__apcest_P}, and
{bf:__apcest_C}, which contain the original numerical APC variables mean-centered
on that sample. These centered variables carry the linear APC components.

{pstd}When a categorical or grouped specification is requested, {cmd:apcest}
additionally creates the corresponding nonlinear working variable
{bf:__apcest_nlA}, {bf:__apcest_nlP}, or {bf:__apcest_nlC}. For categorical
specifications it contains a copy of the source variable; for
{it:varname}:{it:numlist} specifications it contains the grouped values created
by {cmd:egen, cut()}. APC working variables are defined only for observations in
the final estimation sample and are therefore missing outside that sample. They
remain in the active dataset after estimation and are replaced the next time
{cmd:apcest} is run.


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
approach to age-period-cohort analysis (Version 2.2)" [Computer software].
Boston College Department of Economics, Statistical Software Components.
{browse "https://ideas.repec.org/c/boc/bocode/s459449.html":https://ideas.repec.org/c/boc/bocode/s459449.html}
{p_end}

{phang}
{cmd:Yastrebov, G., Trinidad, A., and Leopold, T.} (2025). A Bounding Approach to Age-Period-Cohort Analysis: A Demonstration Using Public Crime Concerns in Germany. {it:Journal of Quantitative Criminology}.
{browse "https://doi.org/10.1007/s10940-025-09633-7":https://doi.org/10.1007/s10940-025-09633-7}
{p_end}
