{smcl}
{* *! version 1.0.0  12feb2023}{...}
{findalias asfradohelp}{...}
{vieweralsosee "posis" "help posis"}{...}

{viewerjumpto "Syntax" "isis##syntax"}{...}
{viewerjumpto "Description" "isis##description"}{...}
{viewerjumpto "Options" "isis##options"}{...}
{viewerjumpto "Examples" "isis##examples"}{...}
{viewerjumpto "Stored results" "isis##results"}{...}
{viewerjumpto "Reference" "isis##reference"}{...}
{title:Title}

{phang}
{bf:isis} {hline 2} Iterative sure independence screening for prediction and
covariate selection


{* ---------------------------------------- SYNTAX}
{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:isis}
{depvar}
{it:controls}
{ifin}
{weight}
{cmd:,}
{cmd:model({help isis##modelspec:{it:model_spec}})}
[{help isis#options:{it:options}}]

{pstd}
{it:controls} are variables that {help isis} will choose to include or exclude
from the model.


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:model({help isis##modelspec:{it:model_spec}})}}specify the
model {p_end}
{synopt : {cmd:method({help isis##methodspec:{it:method_spec}})}}specify the
variable selection technique{p_end}
{synopt: {cmd:always({varlist})}}specify the variables always included in the
model{p_end}
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
{synopt :{cmd:lasso , {help isis##lassospec:{it:lasso_spec}}}}lasso {p_end}
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
* {opt model()} is required.{p_end}
{p 4 6 2}
{cmd:fweight}s and {cmd:iweight}s are allowed. See {help weight}.{p_end}
{p 4 6 2}
For {help isis##modelspec:{it:model_spec}}, only one of {cmd:linear},
{cmd:logit}, or {cmd:poisson} is allowed.{p_end}
{p 4 6 2}
For {help isis##methodspec:{it:method_spec}}, only one of {cmd:stepbic} or
{cmd:lasso} is allowed.
{p_end}
{p 4  6 2}
For {help isis##lassospec:{it:lasso_spec}}, only one of {cmd:cv}, {cmd:plugin},
{cmd:adaptive}, or {cmd:bic} is allowed.  {p_end}

{* ---------------------------------------- Description} 
{marker description}{...}
{title:Description}

{pstd}
{cmd:isis} implements the covariate selector that combines iterative sure
independence screening (ISIS) with Lasso or BIC-based stepwise technique for the
linear, logit, and Poisson models. {cmd:isis} potentially allows for ultra-high
dimensional covariates. The selected variables can be used for prediction or as
an intermediate step in the construction of the Neyman orthogonal estimator
implemented in {help posis} proposed in D. Drukker and D. Liu (2022a) and
(2022b).


{* ---------------------------------------- Options}
{marker options}
{title:Options}

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

{* ---------------------------------------- Examples}
{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse cattaneo2}

{pstd}ISIS linear regression{p_end}
{phang2}
{cmd:. isis bweight c.mage##c.mage c.fage##c.fage c.mage#c.fage c.fedu##c.medu}
	{cmd: i.(mmarried mhisp fhisp foreign alcohol msmoke fbaby prenatal1)}
	{cmd:, model(linear)}

{pstd}As above but use plugin-based LASSO{p_end}
{phang2}
{cmd:. isis bweight c.mage##c.mage c.fage##c.fage c.mage#c.fage c.fedu##c.medu}
	{cmd: i.(mmarried mhisp fhisp foreign alcohol msmoke fbaby prenatal1)}
	{cmd:, model(linear) method(lasso, plugin)}

{pstd}As above but use BIC-based stepwise{p_end}
{phang2}
{cmd:. isis bweight c.mage##c.mage c.fage##c.fage c.mage#c.fage c.fedu##c.medu}
	{cmd: i.(mmarried mhisp fhisp foreign alcohol msmoke fbaby prenatal1)}
	{cmd:, model(linear) method(stepbic)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:isis} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt: {cmd: e(N)}}  number of observations {p_end}
{synopt: {cmd: e(screen_size)}} screen size {p_end}
{synopt: {cmd: e(k_controls)}} number of control variables {p_end}
{synopt: {cmd: e(iter)}} actual number of iterations {p_end}
{synopt: {cmd: e(maxiter)}} maximum number of iterations {p_end}
{synopt: {cmd: e(k_controls_sel)}} number of selected controls {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt: {cmd :e(cmd_extend)}} {cmd:isis} {p_end}
{synopt: {cmd :e(title)}} coefficient table title {p_end}
{synopt: {cmd :e(selopt)}} selection method suboptions {p_end}
{synopt: {cmd :e(selcmd)}} selection method command {p_end}
{synopt: {cmd :e(depvar)}} depvar {p_end}
{synopt: {cmd :e(model)}} model {p_end}
{synopt: {cmd :e(allvars_sel)}} name of the selected variables {p_end}
{synopt: {cmd :e(allvars)}} name of all the variables {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt: {cmd:e(b)}}coefficient vector {p_end}

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

