{smcl}
{* *! version 0.4.5  08nov2025}{...}
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
{synopt:{opt table}}display comparison table of estimates across groups{p_end}
{synopt:{opt combined}}display combined mean and variance equation tables{p_end}
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
{opt table} requests a comparison table of the mean equation estimates across 
all groups using {helpb esttab} (if installed). The table includes iteration 
counts, convergence status, and final log-likelihood values.

{phang}
{opt combined} displays two additional tables: (1) mean equation results for 
all groups side-by-side, and (2) variance equation results for all groups 
side-by-side. This option requires {helpb esttab} to be installed 
({stata ssc install estout}). This provides an easy way to compare coefficients 
across groups.


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
iterations and the initial and final log-likelihood values.

{pstd}
{bf:Stored estimates}: The command stores three sets of estimates for each group 
(where [group] is the group identifier):

{p 8 12}{cmd:beta_[group]} - Mean equation estimates with metadata (main results){p_end}
{p 8 12}{cmd:mean_[group]} - Mean equation estimates{p_end}
{p 8 12}{cmd:var_[group]} - Variance equation estimates{p_end}

{pstd}
These can be replayed with {helpb estimates replay} or {helpb estimates table}, 
and can be used with {helpb esttab}, {helpb etable}, or the {helpb collect} system.

{pstd}
{bf:Interpretation}: Coefficients in the mean equation are interpreted as in 
standard linear regression. Coefficients in the variance equation are on the log 
scale (due to the log link): positive coefficients indicate that the variable 
increases variance, while negative coefficients indicate that it decreases variance.


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
{phang2}{cmd:. gen sampwgt = 1}{p_end}

{pstd}Declare panel structure{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Basic estimation by region (south) with probability weights{p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure)}{p_end}

{pstd}With combined tables{p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) combined}{p_end}

{pstd}Suppress iteration log{p_end}
{phang2}{cmd:. xtvfreg ln_wage, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) nolog}{p_end}

{pstd}Display comparison table across groups with sampling weights{p_end}
{phang2}{cmd:. xtvfreg ln_wage [pweight=sampwgt], groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) table}{p_end}

{pstd}Display comparison table across groups with if selecion sampling weights{p_end}
{phang2}{cmd:. xtvfreg ln_wage if race==1 [pweight=sampwgt], groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) table}{p_end}

{pstd}Replay stored estimates{p_end}
{phang2}{cmd:. estimates replay beta_0}{p_end}
{phang2}{cmd:. estimates replay mean_1}{p_end}
{phang2}{cmd:. estimates replay var_0}{p_end}

{pstd}Use with esttab{p_end}
{phang2}{cmd:. esttab mean_*, se star(* 0.10 ** 0.05 *** 0.01)}{p_end}
{phang2}{cmd:. esttab var_*, se star(* 0.10 ** 0.05 *** 0.01)}{p_end}

{pstd}Use with etable{p_end}
{phang2}{cmd:. estimates replay mean_0}{p_end}
{phang2}{cmd:. etable}{p_end}

{pstd}Completely silent execution{p_end}
{phang2}{cmd:. xtvfreg ln_wage [pweight=sampwgt] if race==1, groupvar(south) panelid(idcode) meanvars(collgrad mage mhours mtenure dage dhours dtenure) varvars(collgrad mage mhours mtenure dage dhours dtenure) table combined}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtvfreg} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ngroups)}}number of groups estimated{p_end}
{synopt:{cmd:r(maxiter)}}maximum iterations allowed{p_end}
{synopt:{cmd:r(converge)}}convergence criterion{p_end}
{synopt:{cmd:r(group#_iter)}}iterations for group #{p_end}
{synopt:{cmd:r(group#_converged)}}convergence status for group # (1=converged, 0=not){p_end}
{synopt:{cmd:r(group#_ll)}}final log-likelihood for group #{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(groups)}}list of group values{p_end}

{pstd}
For each group, {cmd:xtvfreg} stores estimation results in {cmd:e()} under the names 
{cmd:beta_[group]}, {cmd:mean_[group]}, and {cmd:var_[group]}. These contain standard 
{helpb glm} results plus the following additional items in {cmd:beta_[group]}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(group)}}group identifier value{p_end}
{synopt:{cmd:e(n_iter)}}number of iterations until convergence{p_end}
{synopt:{cmd:e(vf_converged)}}convergence indicator (1=yes, 0=no){p_end}
{synopt:{cmd:e(ll_init)}}initial log-likelihood{p_end}
{synopt:{cmd:e(ll_final)}}final log-likelihood{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(vf_groupvar)}}name of grouping variable{p_end}
{synopt:{cmd:e(vf_groupval)}}value of this group{p_end}
{synopt:{cmd:e(vf_cmd)}}"xtvfreg"{p_end}


{marker references}{...}
{title:References}

{phang}
Mooi-Reci, I., and T. F. Liao. 2025. Unemployment: a hidden source of wage 
inequality? {it:European Sociological Review} 41(3): 382-401.
{browse "https://doi.org/10.1093/esr/jcae052"}


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