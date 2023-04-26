{smcl}
{* *! version 1.0.0  23may2021}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "posw##syntax"}{...}
{viewerjumpto "Description" "posw##description"}{...}
{viewerjumpto "Options" "posw##options"}{...}
{viewerjumpto "Remarks" "posw##remarks"}{...}
{viewerjumpto "Examples" "posw##examples"}{...}
{viewerjumpto "Stored results" "posw##results"}{...}
{viewerjumpto "Reference" "posw##reference"}{...}
{title:Title}

{phang}
{bf:posw} {hline 2} Partialling-out estimator based on stepwise-BIC or
stepwise-testing.

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:posw}
{depvar}
{it:varsofinterest}
{ifin}
{cmd:,}
{cmd:controls(}{it:varlist}{cmd:)}
{cmd:model(linear|logit|poisson)}
[{cmd:method(bic|test)} {cmd:alpha(}{it:#}{cmd:)}]

{pstd}
{it:varsofinterest} are variables for which coefficients and their
standard errors are estimated.


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:controls}({it:varlist})} specify the set of control variables
{p_end}
{p2coldent :* {cmd:model(linear|logit|poisson)}} specify the model
{p_end}
{synopt : {cmd:method(bic|test)}} specify the stepwise method{p_end}
{synopt : {cmd:alpha(}{it:#}{cmd:)}} specify the significance level if
stepwise-testing is used {p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
* {opt controls()} and * {opt model()} are required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:posw} fits a high-dimensional linear, logit or Poisson regression model and
reports standard errors, test statistics, and confidence intervals for specified
covariates of interest.  The stepwise-based partialing-out method developed in
D. Drukker and D. Liu (2021) is used to estimate effects for these variables and
to select from potential control variables to be included in the model.

{marker options}
{title:Options}

{phang}
{cmd:controls(}{it:varlist}{cmd:)}
specifies the set of control variables, which control for omitted variables.
Control variables are also known as confounding variables.  {cmd:posw} uses the
forward stepwise to select the control variables for each of {it:depvar} and
{it:varsofinterest}. {cmd:controls()} is required.

{phang}
{cmd:model(linear|logit|poisson)}
specifies the model for the outcome variable {it:depvar}. It can be one of
{cmd:linear}, {cmd:logit}, or {cmd: poisson} model. {cmd:model()} is required.


{phang}
{cmd:method(bic|test)}
specifies the method used in stepwise covariate-selection. It can be one of
{cmd: bic} and {cmd: test}. Specifying {cmd: bic} implies to use the BIC-based
stepwise.  Specifying {cmd: test} implies to use the testing-based stepwise. The
default is {cmd: bic}.

{phang}
{cmd: alpha(}#{cmd:)}
specifies the level of significance for the testing-based stepwise. The default
is {cmd:0.05}.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse breathe}

{pstd}Partialing-out linear regression for outcome reaction time and inference
on classroom and home nitrogen oxide using stepwise-BIC  to select
controls{p_end}
{phang2}{cmd:. posw react no2_class no2_home,}
    {cmd:controls(i.(meducation overweight msmoke sex) noise sev* age)}
    {cmd:model(linear)}

{pstd}As above but use stepwise-testing to select controls{p_end}
{phang2}{cmd:. posw react no2_class no2_home,}
    {cmd:controls(i.(meducation overweight msmoke sex) noise sev* age)}
    {cmd:model(linear)} {cmd:method(test)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:posw} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt: {cmd: e(N)}}  number of observations {p_end}
{synopt: {cmd: e(k_controls)}}  number of controls {p_end}
{synopt: {cmd: e(k_controls_sel)}}  number of selected controls {p_end}
{synopt: {cmd: e(k_varsofinterest)}}  number of variables of interest {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt: {cmd:e(cmd)}} {cmd:posw}{p_end}
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


{marker reference}{...}
{title:Reference}
{phang}
David M. Drukker and Di Liu, Finite sample results for lasso and stepwise
Neyman-orthogonal Poisson estimators, 2021
{p_end}
