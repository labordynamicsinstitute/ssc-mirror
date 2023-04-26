{smcl}
{* *! version 1.0.0  23may2021}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "posis##syntax"}{...}
{viewerjumpto "Description" "posis##description"}{...}
{viewerjumpto "Options" "posis##options"}{...}
{viewerjumpto "Examples" "posis##examples"}{...}
{viewerjumpto "Stored results" "posis##results"}{...}
{viewerjumpto "Reference" "posis##reference"}{...}
{title:Title}

{phang}
{bf:posis} {hline 2} Partialling-out estimator based on iterative sure
independence screening.

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:posis}
{depvar}
{it:varsofinterest}
{ifin}
{cmd:,}
{cmd:controls(}{it:varlist}{cmd:)}
{cmd:model({help posis##modelspec:{it:model_spec}})}
[{help posis#options:{it:options}}]

{pstd}
{it:varsofinterest} are variables for which coefficients and their
standard errors are estimated.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:controls}({it:varlist})}specify the set of control variables
{p_end}
{p2coldent :* {cmd:model({help posis##modelspec:{it:model_spec}})}}specify the
model {p_end}
{synopt : {cmd:method({help posis##methodspec:{it:method_spec}})}}specify the
variable selection technique{p_end}
{synopt : {cmd:maxiter(}{it:#}{cmd:)}}specify the maximum number of
iterations{p_end}
{synoptline}
{p2colreset}{...}

{marker modelspec}{...}
{synoptset 30}{...}
{synopthdr:model_spec}
{synoptline}
{synopt :{cmd:linear}}linear regression {p_end}
{synopt :{cmd:logit}}logit regression {p_end}
{synopt :{cmd:poisson}}Poisson regression {p_end}
{synoptline}

{marker methodspec}{...}
{synoptset 30}{...}
{synopthdr:method_spec}
{synoptline}
{synopt :{cmd:stepbic}}BIC-based stepwise{p_end}
{synopt :{cmd:lasso , {help posis##lassospec:{it:lasso_spec}}}}lasso {p_end}
{synoptline}

{marker lassospec}{...}
{synoptset 30}{...}
{synopthdr:lasso_spec}
{synoptline}
{synopt :{cmd:cv}}cross-validation{p_end}
{synopt :{cmd:plugin}}plug-in method{p_end}
{synopt :{cmd:adaptive}}adaptive lasso{p_end}
{synopt :{cmd: bic}}minimize BIC; the default{p_end}
{synoptline}

{p 4 6 2}
* {opt controls()} and {opt model()} are required.{p_end}
{p 4 6 2}
For {help posis##modelspec:{it:model_spec}}, only one of {cmd:linear},
{cmd:logit}, or {cmd:poisson} is allowed.{p_end}
{p 4 6 2}
For {help posis##methodspec:{it:method_spec}}, only one of {cmd:stepbic} or
{cmd:lasso} is allowed.
{p_end}
{p 4  6 2}
For {help posis##lassospec:{it:lasso_spec}}, only one of {cmd:cv}, {cmd:plugin},
{cmd:adaptive}, or {cmd:bic} is allowed.  {p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:posis} fits a high-dimensional linear, logit or Poisson regression model
and reports standard errors, test statistics, and confidence intervals for
specified covariates of interest.  The iterative sure-independence screening
partialing-out method developed in D. Drukker and D. Liu (2022a) and (2022b) is
used to estimate effects for these variables and to select from potential
control variables to be included in the model.

{* ---------------------------------------- Options}
{marker options}
{title:Options}

{phang}
{cmd:controls(}{it:varlist}{cmd:)}
specifies the set of control variables, which control for omitted variables.
Control variables are also known as confounding variables.  {cmd:posis} uses the
lasso-based or BIC-stepwise-based iterative sure independence screening to
select the control variables for each of {it:depvar} and {it:varsofinterest}.
{cmd:controls()} is required. 

{phang}
{cmd:model({it:model_spec})}
specifies the model for the outcome variable {it:depvar}. {it:model_spec} can be
one of {cmd:linear}, {cmd:logit}, or {cmd: poisson} model. {cmd:model()} is
required.

{phang}
{cmd:method({it:method_spec})} 
specifies the covariate selection technique to be
used within sure independence screening. {it:method_spec} is one of
{cmd:stepbic} or {cmd:lasso, {it:lasso_spec}}, where {cmd:stepbic} refers to the 
BIC-based forward stepwise methods and {cmd:lasso} refers to the Lasso; see
{help lasso}.

{phang2}
{it:lasso_spec} specifies how to chose the tuning parameter in Lasso, and it can
be one of {cmd:cv}, {cmd:plugin}, {cmd:adaptive}, or {cmd:bic}. See 
{help lasso##selmethod:{it:sel_method}} in {help lasso}.

{phang2}
The default is using Lasso and chosing the tuning parameter by minimizing BIC,
which is equivalent to specifying {cmd:method(lasso, bic)}.

{phang}
{cmd:always({it:varlist})} specifies the variables that will always be included
in the model. The default is none.

{phang}
{cmd:maxiter({it:#})} specifies the maximum number of iterations. The default is
5.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse breathe}

{pstd}Partialing-out linear regression for outcome reaction time and inference
on classroom and home nitrogen oxide using BIC-lasso-based iterative sure
independence screening  to select controls{p_end}
{phang2}{cmd:. posis react no2_class no2_home,}
    {cmd:controls(i.(meducation overweight msmoke sex) noise sev* age)}
    {cmd:model(linear)}

{pstd}As above but use BIC-stepwise-based iterative sure independence screening
to select controls{p_end}
{phang2}{cmd:. posis react no2_class no2_home,}
    {cmd:controls(i.(meducation overweight msmoke sex) noise sev* age)}
    {cmd:model(linear)} {cmd:method(stepbic)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:posis} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt: {cmd: e(N)}}  number of observations {p_end}
{synopt: {cmd: e(k_controls)}}  number of controls {p_end}
{synopt: {cmd: e(k_controls_sel)}}  number of selected controls {p_end}
{synopt: {cmd: e(k_varsofinterest)}}  number of variables of interest {p_end}
{synopt: {cmd: e(rank)}} rank of e(V) {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt: {cmd:e(cmd)}} {cmd:posis}{p_end}
{synopt: {cmd:e(varsofinterest)}} variables of interest {p_end}
{synopt: {cmd:e(depvar)}} dependent variable {p_end}
{synopt: {cmd:e(controls_sel)}} selected control variables {p_end}
{synopt: {cmd:e(controls)}} control variables {p_end}
{synopt: {cmd:e(model)}} type of model {p_end}
{synopt: {cmd:e(title)}} title in estimation output {p_end}
{synopt: {cmd:e(vcetype)}} robust {p_end}
{synopt: {cmd:e(vce)}} Robust {p_end}
{synopt: {cmd:e(properties)}} {cmd:b V} {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt: {cmd:e(b)}}coefficient vector {p_end}
{synopt: {cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}



{* ---------------------------------------- Reference}
{marker reference}{...}
{title:Reference}

{phang}
Drukker, D. M., and D. Liu. 2022a. Finite-sample results for lasso and stepwise
Neyman-orthogonal Poisson estimators. Econometric Reviews 41(9): 1047–1076.

{phang}
Drukker, D. M., and D. Liu. 2022b. posis: Stata command for the
sure-independence-screening Neyman-orthogonal estimator.
