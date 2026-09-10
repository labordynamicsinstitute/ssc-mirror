{smcl}
{* *! version 0.4.8  25nov2025}{...}
{viewerjumpto "Syntax" "xtvfreg##syntax"}{...}
{viewerjumpto "Description" "xtvfreg##description"}{...}
{viewerjumpto "Options" "xtvfreg##options"}{...}
{viewerjumpto "Remarks" "xtvfreg##remarks"}{...}
{viewerjumpto "Examples" "xtvfreg##examples"}{...}
{viewerjumpto "Stored results" "xtvfreg##results"}{...}
{viewerjumpto "References" "xtvfreg##references"}{...}
{viewerjumpto "Author" "xtvfreg##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:xtvfreg} {hline 2}}Varying fixed effects panel regression with heteroscedastic variance function{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtvfreg}
{depvar}
{ifin}
{weight}
{cmd:,}
{opt groupvar(varname)}
{opt panelid(varname)}
{opt meanvars(varlist)}
{opt varvars(varlist)}
[{it:options}]

{pstd}
{cmd:pweight}s are allowed; see {help weight}.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt groupvar(varname)}}grouping variable for separate estimations{p_end}
{p2coldent:* {opt panelid(varname)}}panel identifier variable{p_end}
{p2coldent:* {opt meanvars(varlist)}}covariates for mean equation{p_end}
{p2coldent:* {opt varvars(varlist)}}covariates for variance equation{p_end}

{syntab:Options}
{synopt:{opt tvar(varname)}}time variable (optional, currently not used){p_end}
{synopt:{opt converge(real)}}convergence tolerance; default is {cmd:converge(1e-6)}{p_end}
{synopt:{opt maxiter(integer)}}maximum iterations; default is {cmd:maxiter(100)}{p_end}
{synopt:{opt nolog}}suppress iteration log{p_end}
{synopt:{opt table}}display a single wide table of mean-equation estimates with 
diagnostic scalars (iterations, convergence, log-likelihood, variance decomposition) 
across groups{p_end}
{synopt:{opt combined}}display two separate tables: mean equation estimates for 
all groups, followed by variance equation estimates for all groups{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt groupvar()}, {opt panelid()}, {opt meanvars()}, and {opt varvars()} are required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtvfreg} implements an iterative mean-variance panel regression estimator 
that allows both the mean and variance of the dependent variable to be functions 
of covariates. The method is based on Mooi-Reci & Liao (2025) and consists of 
iteratively estimating:

{p 8 12}(1) A mean equation using generalized linear models (GLM) with Gaussian 
family and identity link{p_end}

{p 8 12}(2) A variance equation using GLM with Gamma family and log link, 
applied to squared within-group (fixed effects) residuals{p_end}

{pstd}
The algorithm alternates between these two steps, using the estimated variance 
from step (2) as analytic weights in step (1), until the change in the 
log-likelihood of the variance equation falls below the convergence criterion.

{pstd}
When probability weights ({cmd:pweight}s) are specified, they are combined with 
the algorithm's analytic variance weights. Specifically, the combined weight used 
in the mean equation is {it:pweight}/S², where S² is the estimated variance 
function. This ensures both the sampling design and heteroscedasticity are 
properly accounted for.

{pstd}
The command estimates separate models for each level of the grouping variable, 
allowing the mean and variance structures to differ across groups. This is 
particularly useful for studying heterogeneity in both location and scale 
parameters across subpopulations.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt groupvar(varname)} specifies the grouping variable. The command loops over 
each distinct level of this variable and runs the iterative estimation separately 
for each group. This allows the mean and variance parameters to differ across groups.

{phang}
{opt panelid(varname)} specifies the panel identifier variable. This is used for 
the within (fixed-effects) transformation via {helpb xtreg} with the {cmd:fe} option. 
The panel structure must be declared with {helpb xtset} before running {cmd:xtvfreg}.

{phang}
{opt meanvars(varlist)} lists the covariates to include in the mean (location) 
equation. These variables predict the expected value of the dependent variable.

{phang}
{opt varvars(varlist)} lists the covariates to include in the variance (scale) 
equation. These variables model heteroscedasticity by predicting the variance of 
the dependent variable. The variance model uses squared within-group residuals as 
the dependent variable. {opt varvars()} may overlap with {opt meanvars()}.

{dlgtab:Options}

{phang}
{opt tvar(varname)} optionally specifies a time variable. Currently not used in 
the estimation but may be used for future extensions.

{phang}
{opt converge(real)} sets the convergence tolerance for the iterative algorithm. 
Convergence is achieved when the absolute change in the summed log-likelihood of 
the variance equation between iterations falls below this threshold. The default 
is {cmd:converge(1e-6)}.

{phang}
{opt maxiter(integer)} sets the maximum number of iterations allowed before 
stopping the algorithm. A warning is displayed if convergence is not achieved 
within this limit. The default is {cmd:maxiter(100)}.

{phang}
{opt nolog} suppresses the display of the iteration log, which shows the 
log-likelihood value and change at each iteration for each group.

{phang}
{opt table} requests a single wide comparison table, using {helpb esttab} (if 
installed), of the {bf:mean equation} estimates for every group side by side, 
annotated with diagnostic scalars: number of iterations, convergence status, 
final log-likelihood, total variance, and the two variance-decomposition 
proportions. This table does {bf:not} include the variance equation; use 
{opt combined} (or {cmd:estimates replay var_[group]}) for that.

{phang}
{opt combined} displays two additional tables, using {helpb esttab} (if 
installed): (1) mean equation results for all groups side by side, and 
(2) variance equation results for all groups side by side, each with 
coefficients and standard errors. This option requires {helpb esttab} to be 
installed ({stata ssc install estout}).

{pstd}
{opt table} and {opt combined} are independent and can be used together; doing 
so will display three tables in sequence (the diagnostics table from 
{opt table}, then the plain mean-equation table and the variance-equation table 
from {opt combined}). The mean equation therefore appears twice, in two 
different formats (once with diagnostic scalars, once with standard errors); 
this is expected and not a bug.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:xtvfreg} uses an iterative weighted generalized least squares (GLS) approach:

{p 8 12}1. Initial estimation: Fit the mean model with {helpb glm} using 
{cmd:family(gaussian)} and {cmd:link(identity)}. Compute residuals.{p_end}

{p 8 12}2. Within transformation: Run {helpb xtreg:xtreg, fe} on the residuals 
to extract within-group (fixed effects) residuals. Square these residuals to 
obtain the dependent variable for the variance equation.{p_end}

{p 8 12}3. Variance estimation: Fit a variance model via {helpb glm} with 
{cmd:family(gamma)} and {cmd:link(log)} using the squared residuals. This 
estimates the variance function S².{p_end}

{p 8 12}4. Weighted re-estimation: Re-estimate the mean model using analytic 
weights {cmd:[aw=1/S²]}, which accounts for heteroscedasticity.{p_end}

{p 8 12}5. Iteration: Repeat steps 2-4 until the change in the log-likelihood 
of the variance equation is less than the convergence tolerance.{p_end}

{pstd}
For each group, convergence information is displayed showing the number of 
iterations and the initial and final log-likelihood values. The command also 
reports a variance decomposition that partitions the total variance of the 
dependent variable into three components:

{p 8 12}1. {bf:Variance explained by mean model} - The variance of fitted values 
from the weighted mean equation. This represents systematic variation captured by 
the mean predictors (covariates).{p_end}

{p 8 12}2. {bf:Variance explained by variance model} - The mean of the estimated 
variance function (S²). This represents the average level of heteroscedasticity 
modeled by the variance equation predictors.{p_end}

{p 8 12}3. {bf:Unexplained variance} - The remaining variance not accounted for 
by the mean and variance models. This includes individual fixed effects and 
idiosyncratic variation not captured by the models.{p_end}

{pstd}
Each component is expressed both in absolute terms (variance units) and as a 
percentage of total variance. These proportions help assess the relative 
importance of the mean structure and heteroscedasticity in explaining variation 
in the outcome.

{pstd}
{bf:Stored estimates}: The command stores {bf:two} sets of estimates for each 
group (where [group] is the group identifier):

{p 8 12}{cmd:mean_[group]} - Mean equation estimates, with diagnostic and 
variance-decomposition scalars attached via {helpb estadd} (this is the main, 
full result for the group){p_end}
{p 8 12}{cmd:var_[group]} - Variance equation estimates{p_end}

{pstd}
There is no separate {cmd:beta_[group]} set; {cmd:mean_[group]} already carries 
both the coefficients and the diagnostics. To see the mean equation with all 
metadata, use {cmd:estimates replay mean_[group]}. To see the variance equation, 
use {cmd:estimates replay var_[group]}.

{pstd}
These can be replayed with {helpb estimates replay} or {helpb estimates table}, 
and can be used with {helpb esttab}. Combining multiple stored estimates into a 
single {helpb etable} requires the {cmd:estimates()} option (Stata 17+); see the 
examples below. Running {cmd:etable} with no arguments after 
{cmd:estimates replay} only shows the single currently active estimate, and 
running {cmd:etable, replay ...} before any {helpb collect} results exist will 
produce the error {bf:"Your layout specification does not identify any items."} 
because there is nothing yet to replay.

{pstd}
{bf:Interpretation}: Coefficients in the mean equation are interpreted as in 
standard linear regression. Coefficients in the variance equation are on the log 
scale (due to the log link): positive coefficients indicate that the variable 
increases variance, while negative coefficients indicate that it decreases variance. 
Exponentiate a variance-equation coefficient (e.g., {cmd:exp(_b[x])}) to obtain 
the multiplicative effect on the variance.

{pstd}
{bf:Temporary variables}: The command creates group-specific temporary variables 
named {cmd:R2_[group]} and {cmd:S2_[group]} during estimation. These are 
automatically dropped when the command finishes, so no manual cleanup is needed 
before rerunning the model.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}

{pstd}Create within-group means and deviations{p_end}
{phang2}{cmd:. egen mage = mean(age), by(idcode)}{p_end}
{phang2}{cmd:. egen mhours = mean(hours), by(idcode)}{p_end}
{phang2}{cmd:. egen mtenure = mean(tenure), by(idcode)}{p_end}
{phang2}{cmd:. gen dage = age - mage}{p_end}
{phang2}{cmd:. gen dhours = union - mhours}{p_end}
{phang2}{cmd:. gen dtenure = tenure - mtenure}{p_end}

{pstd}Declare panel structure{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Basic estimation by region (south){p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure)}{p_end}

{pstd}Mean-equation diagnostics table only (one wide table, includes variance decomposition){p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) table}{p_end}

{pstd}Mean AND variance equation tables side by side (two tables){p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) combined}{p_end}

{pstd}Suppress iteration log{p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) nolog}{p_end}

{pstd}With probability weights{p_end}
{phang2}{cmd:. gen sampwgt = 1}{p_end}
{phang2}{cmd:. xtvfreg ln_wage [pweight=sampwgt], groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) combined}{p_end}

{pstd}With an {cmd:if} condition{p_end}
{phang2}{cmd:. xtvfreg ln_wage if race==1, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) combined}{p_end}

{pstd}Replay a single stored estimate{p_end}
{phang2}{cmd:. estimates replay mean_0}{p_end}
{phang2}{cmd:. estimates replay var_0}{p_end}
{phang2}{cmd:. estimates replay mean_1}{p_end}
{phang2}{cmd:. estimates replay var_1}{p_end}

{pstd}Use with esttab{p_end}
{phang2}{cmd:. esttab mean_*, se star(* 0.10 ** 0.05 *** 0.01)}{p_end}
{phang2}{cmd:. esttab var_*, se star(* 0.10 ** 0.05 *** 0.01)}{p_end}

{pstd}Use with etable for a single group (no {cmd:estimates()} needed - the most 
recently replayed estimate is used){p_end}
{phang2}{cmd:. estimates replay mean_0}{p_end}
{phang2}{cmd:. etable, title(Table 1. Group 0 Mean Equation) stars(0.10 "*" 0.05 "**" 0.01 "***")}{p_end}

{pstd}Use with etable to combine multiple groups into one table (requires the 
{cmd:estimates()} option, Stata 17+; do {bf:not} use {cmd:replay} the first time 
since nothing has been collected yet){p_end}
{phang2}{cmd:. etable, estimates(mean_0 mean_1) title(Table 2. Regression Estimates) stars(0.05 "*" 0.01 "**" 0.001 "***") export(RegResults.docx, replace)}{p_end}

{pstd}Only after the above has run once does a collection exist to replay; here 
we reformat it with looser star thresholds and no exported file{p_end}
{phang2}{cmd:. etable, replay stars(0.10 "*" 0.05 "**" 0.01 "***")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtvfreg} is an {bf:e-class} command. It stores the following in {cmd:e()} 
after the full command finishes (these describe the overall run, indexed by 
group number {cmd:#} = 1, 2, ...):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(ngroups)}}number of groups estimated{p_end}
{synopt:{cmd:e(maxiter)}}maximum iterations allowed{p_end}
{synopt:{cmd:e(converge)}}convergence criterion{p_end}
{synopt:{cmd:e(group#_iter)}}iterations for group #{p_end}
{synopt:{cmd:e(group#_converged)}}convergence status for group # (1=converged, 0=not){p_end}
{synopt:{cmd:e(group#_ll)}}final log-likelihood for group #{p_end}
{synopt:{cmd:e(group#_var_total)}}total variance of dependent variable for group #{p_end}
{synopt:{cmd:e(group#_prop_mean)}}proportion of variance explained by mean model for group #{p_end}
{synopt:{cmd:e(group#_prop_var)}}proportion of variance explained by variance model for group #{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(groups)}}list of group values{p_end}

{pstd}
These can be viewed after {cmd:xtvfreg} finishes with {cmd:ereturn list}, or 
individual scalars can be displayed directly, e.g. {cmd:display e(ngroups)}. 
Note that because {cmd:xtvfreg} is e-class (not r-class), {cmd:r()} results such 
as {cmd:r(ngroups)} are {bf:not} set; use the {cmd:e()} names above instead.

{pstd}
In addition, for each group {cmd:xtvfreg} stores estimation results in {cmd:e()} 
under {cmd:mean_[group]} and {cmd:var_[group]} (see {help xtvfreg##remarks:Remarks} 
above). These contain standard {helpb glm} results. The {cmd:mean_[group]} 
estimates additionally carry:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars (in mean_[group])}{p_end}
{synopt:{cmd:e(group)}}group identifier value{p_end}
{synopt:{cmd:e(n_iter)}}number of iterations until convergence{p_end}
{synopt:{cmd:e(vf_converged)}}convergence indicator (1=yes, 0=no){p_end}
{synopt:{cmd:e(ll_init)}}initial log-likelihood{p_end}
{synopt:{cmd:e(ll_final)}}final log-likelihood{p_end}
{synopt:{cmd:e(var_total)}}total variance of dependent variable{p_end}
{synopt:{cmd:e(var_fitted)}}variance explained by mean model{p_end}
{synopt:{cmd:e(var_heterosced)}}variance explained by variance model (mean of S²){p_end}
{synopt:{cmd:e(prop_mean)}}proportion of variance explained by mean model{p_end}
{synopt:{cmd:e(prop_var)}}proportion of variance explained by variance model{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros (in mean_[group])}{p_end}
{synopt:{cmd:e(vf_groupvar)}}name of grouping variable{p_end}
{synopt:{cmd:e(vf_groupval)}}value of this group{p_end}
{synopt:{cmd:e(vf_cmd)}}"xtvfreg"{p_end}

{pstd}
These group-specific scalars/macros are only available after 
{cmd:estimates replay mean_[group]}, not from the top-level {cmd:e()} left 
behind by the full {cmd:xtvfreg} call (which instead has the 
{cmd:e(group#_...)} scalars listed above).


{marker references}{...}
{title:References}

{phang}
Mooi-Reci, I., and T. F. Liao. 2025. Unemployment: a hidden source of wage 
inequality? {it:European Sociological Review} 41(3): 382-394.
{browse "https://doi.org/10.1093/esr/jcae029"}


{marker author}{...}
{title:Author}

{pstd}
Tim F. Liao{break}
University of Illinois Urbana-Champaign{break}
tfliao@illinois.edu


{title:Also see}

{psee}
Manual:  {manlink R glm}, {manlink XT xtreg}

{psee}
Online:  {helpb glm}, {helpb xtreg}, {helpb xtset}, {helpb estimates}, 
{helpb esttab} (if installed), {helpb etable} (if installed)
{p_end}
