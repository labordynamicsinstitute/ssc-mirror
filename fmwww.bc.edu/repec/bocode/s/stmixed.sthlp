{smcl}
{* *! version 1.0.0 2012}{...}
{vieweralsosee "stmixed postestimation" "help stmixed postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtmelogit" "help xtmelogit"}{...}
{vieweralsosee "[XT] xtmepoisson" "help xtmepoisson"}{...}
{vieweralsosee "[ST] streg" "help streg"}{...}
{vieweralsosee "stpm2" "help stpm2"}{...}
{viewerjumpto "Syntax" "stmixed##syntax"}{...}
{viewerjumpto "Description" "stmixed##description"}{...}
{viewerjumpto "Options" "stmixed##options"}{...}
{viewerjumpto "Remarks" "stmixed##remarks"}{...}
{viewerjumpto "Examples" "stmixed##examples"}{...}
{viewerjumpto "Reference" "stmixed##reference"}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{synopt :{cmd:stmixed} {hline 2}}Multilevel mixed effects parametric survival analysis
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:stmixed} [{it:fe_equation}] {cmd:||} {it:re_equation}
        [{cmd:,} {it:{help stmixed##options_table:options}}]

{p 4 4 2}
    where the syntax of {it:fe_equation} is

{p 12 24 2}
        [{varlist}] {ifin} [{cmd:,} {it:{help stmixed##fe_options:fe_options}}]

{p 4 4 2}
    and the syntax of {it:re_equation} for random coefficients and intercept is

{p 12 24 2}
        {it:{help varname:levelvar}}{cmd::} [{varlist}]
                [{cmd:,} {it:{help xtmixed##re_options:re_options}}]

{p 4 4 2}
    {it:levelvar} is a variable identifying the group structure for the random
    effects at that level.{p_end}

{synoptset 29 tabbed}{...}
{marker fe_options}{...}
{synopthdr :fe_options}
{synoptline}
{syntab:Model}
{synopt :{opt noc:onstant}}suppress constant term from the fixed-effects equation{p_end}
{synoptline}

{marker re_options}{...}
{synopthdr :re_options}
{synoptline}
{syntab:Model}
{synopt :{opth cov:ariance(stmixed##vartype:vartype)}}variance-covariance structure of the random effects{p_end}
{synopt :{opt noc:onstant}}suppress constant term from the random-effects equation{p_end}
{synoptline}

{synoptset 29}{...}
{marker vartype}{...}
{synopthdr :vartype}
{synoptline}
{synopt :{opt ind:ependent}}one variance parameter per random effect, 
all covariances zero; the default unless a factor variable is specified{p_end}
{synopt :{opt ex:changeable}}equal variances for random effects, 
and one common pairwise covariance{p_end}
{synopt :{opt id:entity}}equal variances for random effects, all 
covariances zero; the default for factor variables{p_end}
{synopt :{opt un:structured}}all variances and covariances distinctly 
estimated{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{marker options_table}{...}
{synopthdr :options}
{synoptline}
{syntab:Model}
{synopt:{cmdab:d:istribution(}{cmdab:e:xponential)}}exponential survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:gom:pertz)}}Gompertz survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:w:eibull)}}Weibull survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:fpm)}}flexible parametric survival model{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:logl:ogistic)}}log logistic survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:ll:ogistic)}}synonym for {bf:distribution(loglogistic)}{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:logn:ormal)}}log normal survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:ln:ormal)}}synonym for {bf:distribution(lognormal)}{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:gam:ma)}}generalised gamma survival distribution{p_end}
{synopt:{cmdab:df(#)}}degrees of freedom for baseline hazard function with {bf:d(fpm)}{p_end}
{synopt:{opt dft:vc(df_list)}}degrees of freedom for each time-dependent effect with {bf:d(fpm)}{p_end}
{synopt:{opt knots(numlist)}}knot locations for baseline hazard with {bf:d(fpm)}{p_end}
{synopt:{opt knotst:vc(numlist)}}knot locations for time-dependent effects with {bf:d(fpm)}{p_end}
{synopt:{opt tvc(varlist)}}varlist of time-dependent effects with {bf:d(fpm)}{p_end}

{syntab:Integration}
{synopt:{opt gh(#)}}number of Gauss-Hermite quadrature points; default is {bf:gh(9)}{p_end}
{synopt:{opt nonadapt}}use non-adaptive Gauss-Hermite quadrature{p_end}

{syntab:Reporting}
{synopt:{opt keepc:ons}}do not drop constraints used in ml routine with {bf:d(fpm)}{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt showinit}}display output from initial value model fits{p_end}
{synopt:{opt var:iance}}show random effects parameter estimates as variances and covariances{p_end}

{syntab:Maximization options}
{synopt:{opt initmat:rix(matname)}}matrix of initial values{p_end}
{synopt:{it:{help stmixed##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synopt:{opt retol:erance(#)}}tolerance for random effects estimates; default is {bf:retolernace(1e-08)}; seldom used{p_end}
{synopt:{opt reiter:ate(#)}}maximum number of iterations for random effects estimation; default is {bf:reiterate(200)}; seldom used{p_end}
{synopt :{opt refine:opts}{cmd:(}{it:{help stmixed##maximize_options:maximize_options}}{cmd:)}}control the maximization process during refinement of starting values{p_end}
{synopt:{opt showadapt}}display adaptive log-likelihood iteration log{p_end}
{synopt:{opt vcvinitmat:rix(matname)}}matrix of initial values for variance-covariance random effect parameters{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stmixed}; see {manhelp stset ST}. {p_end}
{p 4 6 2}
Weights are not currently supported.{p_end}
{p 4 6 2}
Factor variables are not currently supported.{p_end}


{title:Description}

{pstd}
{cmd:stmixed} fits multilevel mixed effects parametric survival models using maximum likelihood. The distribution of the random effects is assumed 
to be Gaussian. Adaptive or non-adaptive Gauss-Hermite quadrature is used to evaluate the likelihood. Parametric survival models available include 
the exponential, Weibull, and Gompertz proportional hazards models, log-logistic, log-normal, and generalised gamma accelerated failure time models, 
and the Royston-Parmar flexible parametric survival model. Currently only two levels in the model are supported. The random effects are included in 
the linear predictor on the log hazard scale for proportional hazards models, and the log time scale for accelerated failure time models. In particular, 
{cmd:stmixed} provides normally distributed frailties as an alternative to those implemented in {cmd:streg} (gamma and inverse normal), as well as allowing 
random slopes. More details can be found in {it:Crowther et al.} (2014).
{p_end}

{pstd}
See {helpb stmixed postestimation} for a variety of predictions and residuals that can be calculated following a model fit.
{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt noconstant} suppresses the constant (intercept) term and may be specified for the fixed effects equation and for the random effects equation.
{p_end}

{phang}{opt covariance(vartype)}, where {it:vartype} is

{phang3}
{cmd:independent}{c |}{cmd:exchangeable}{c |}{cmd:identity}{c |}{cmd:unstructured}

{pmore}
specifies the structure of the covariance
matrix for the random effects. An {cmd:independent} covariance structure allows a distinct
variance for each random effect within a random-effects equation and 
assumes that all covariances are zero.  {cmd:exchangeable} covariances
have common variances and one common pairwise covariance.  {cmd:identity}
is short for "multiple of the identity"; that is, all variances are equal
and all covariances are zero.  {cmd:unstructured} allows for
all variances and covariances to be distinct.  If an equation consists of
{it:p} random-effects terms, the {cmd:unstructured} covariance matrix will have
{it:p}({it:p}+1)/2 unique parameters.

{pmore}
{cmd:covariance(unstructured)} is the default.

{phang}
{opt distribution(string)} specifies the survival distribution.

{pmore}
{cmd:distribution(exponential)} fits an exponential survival model.

{pmore}
{cmd:distribution(weibull)} fits a Weibull survival model.

{pmore}
{cmd:distribution(gompertz)} fits a Gompertz survival model.

{pmore}
{cmd:distribution(loglogistic)} fits a log logistic survival model.

{pmore}
{cmd:distribution(lognormal)} fits a log normal survival model.

{pmore}
{cmd:distribution(gamma)} fits a generalised gamma survival model.

{pmore}
{cmd:distribution(fpm)} fits a flexible parametric survival model. This is a highly flexible fully parametric alternative to the Cox 
model, modelled on the log cumulative hazard scale using restricted cubic splines. For more details see {helpb stpm2}.

{phang}
{opt df(#)} specifies the degrees of freedom for the restricted cubic spline function used for the baseline function under a flexible 
parametric survival model. {it:#} must be between 1 and 10, but usually a value between 1 and 4 is sufficient. The {cmd:knots()} option 
is not applicable if the {cmd:df()} option is specified. The knots are placed at the following centiles of the distribution of the 
uncensored log survival times:

        {hline 60}
        df  knots        Centile positions
        {hline 60}
         1    0    (no knots)
         2    1    50
         3    2    33 67
         4    3    25 50 75
         5    4    20 40 60 80
         6    5    17 33 50 67 83
         7    6    14 29 43 57 71 86
         8    7    12.5 25 37.5 50 62.5 75 87.5
         9    8    11.1 22.2 33.3 44.4 55.6 66.7 77.8 88.9
        10    9    10 20 30 40 50 60 70 80 90     
        {hline 60}
        
{pmore}
Note that these are {it:interior knots} and there are also boundary knots
placed at the minimum and maximum of the distribution of uncensored survival
times. 

{phang}
{opt dftvc(df_list)} gives the degrees of freedom for time-dependent effects
in {it:df_list}. The potential degrees of freedom are listed under the
{opt df()} option. With 1 degree of freedom a linear effect of log time is fitted.
If there is more than one time-dependent effect and different degress of freedom
are requested for each time-dependent effect then the following syntax applies:

{pmore}
{cmd:dftvc(x1:3 x2:2 1)}

{pmore}
This will use 3 degrees of freedom for {cmd:x1}, 2 degrees of freedom for
{cmd:x2} and 1 degree of freedom for all remaining time-dependent effects. 

{phang}
{opt knots(numlist)} specifies knot locations for the baseline distribution function under a flexible parametric survival model, as opposed to the default 
locations set by df(). Note that the locations of the knots are placed on the standard time scale. However, the scale used by the restricted cubic spline 
function is always log time. Default knot positions are determined by the df() option.

{phang}
{opt knotstvc(knotslist)} defines numlist {it:knotslist} as the location
of the interior knots for time-dependent effects. If different knots 
are required for different time-dependent effects the option is
specified, for example, as follows:

{pmore}
{cmd:knotstvc(x1 1 2 3 x2 1.5 3.5)}

{phang}
{opt tvc(varlist)} gives the name of the variables that are time-dependent when fitting a flexible parametric model.
Time-dependent effects are fitted using restricted cubic splines. The degrees of freedom are specified using the {opt dftvc()} option. 

{dlgtab:Integration}

{phang}
{opt gh(#)} specifies the number of Gauss-Hermite quadrature nodes used to evaluate the integrals over the random effects. Minimum number of 
quadrature points is 2. Default is 9.
{p_end}

{phang}
{opt nonadapt} use non-adaptive Gauss-Hermite quadrature to evaluate the joint likelihood. This will generally require a much higher number of nodes, {cmd:gh()}, 
to ensure accurate estimates and standard errors, resulting in much greater computation time.{p_end}

{dlgtab:Reporting}

{phang}
{opt keepcons} do not drop the constraints used by ml when fitting a flexible parametric model.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt showinit} displays the output from the inital value model fit using {helpb streg} or {helpb stpm2}.

{phang}
{opt variance} show random effect parameter estimates as variances and covariances, as opposed to the default of 
standard deviations and correlations.

{dlgtab:Maximization}

{phang}
{opt initmatrix(matname)} pass a matrix of initial values to ml, instead of the fixed effect models used to obtain starting values.
{p_end}

{marker maximize_options}{...}
{phang}
{it:maximize_options}; {opt dif:ficult}, {opt tech:nique(algorithm_spec)}, 
{opt iter:ate(#)}, [{opt no:}]{opt lo:g}, {opt tr:ace}, {opt grad:ient}, 
{opt showstep}, {opt hess:ian}, {opt shownr:tolerance}, {opt tol:erance(#)}, 
{opt ltol:erance(#)} {opt gtol:erance(#)}, {opt nrtol:erance(#)}, 
{opt nonrtol:erance}, {opt from(init_specs)}; see {manhelp maximize R}.  These 
options are seldom used, but the {opt difficult} option may be useful if there
are convergence problems.

{phang}
{opt retolerance(#)} specifies the convergence tolerance for the estimated random effects used by adaptive Gaussian quadrature. Gaussian quadrature 
points are adapted to be centered at the estimated random effects given a current set of model parameters. Estimating these random effects is an 
iterative procedure, with convergence declared when the maximum relative change in the random effects is less than {bf:retolerance()}. The default 
{bf:retolerance()} is 1e-8. You should seldom have to use this option.

{phang}
{opt reiterate(#)} specifies the maximum number of iterations used when estimating the random effects to be used in adapting the Gaussian quadrature 
points; see the {bf:retolerance()} option.  The default is {bf:reiterate(200)}.  You should seldom have to use this option.

{phang}
{opt refineopts}{cmd:(}{it:{help stmixed##maximize_options:maximize_options}}{cmd:)} controls the maximization process during the refinement of starting values. Estimation in {bf:stmixed} takes 
place in two stages (unless {bf:nonadapt} is specified). In the first stage, starting values are refined by holding the quadrature points fixed between iterations, i.e. non-adaptive quadrature. 
During the second stage, quadrature points are adapted with each evaluation of the log likelihood. Maximization options specified within {bf:refineopts()} 
control the first stage of optimization; that is, they control the refining of starting values.

{pmore}
{it:maximize_options} specified outside {bf:refineopts()} control the second stage.
		
{pmore}
Refining starting values helps make the iterations of the second stage (those that lead toward the solution) more numerically stable. In this 
regard, of particular interest is {bf:refineopts(iterate(#))}, with two iterations being the default. Should the maximization fail because of 
instability in the Hessian calculations, one possible solution may be to increase the number of iterations here.

{phang}
{opt showadapt} display the log-likelihood iteration log under the sub-iterations used to assess convergence of the adaptive quadrature 
implemented at the beginning of each full Newton-Raphson iteration.{p_end}

{phang}
{opt vcvinitmatrix(matname)} pass a matrix of initial values for the variance-covariance parameters. They should be on the log(standard deviation) and tanh(correlation) scales.
{p_end}


{title:Example 1}

{pstd}This is a simulated example dataset representing a multi-centre trial scenario, with 100 centres and each centre recuiting 60 patients, resulting in 
6000 observations. Two covariates were collected, a binary covariate {bf:x1} (coded 0/1), and a continuous covariate, {bf:x2}, within the range [0,1].{p_end}

{pstd}Load dataset:{p_end}
{phang}{stata "use http://fmwww.bc.edu/repec/bocode/s/stmixed_example1":. use http://fmwww.bc.edu/repec/bocode/s/stmixed_example1}{p_end}

{pstd}stset the data:{p_end}
{phang}{stata "stset stime, f(event=1)":. stset stime, f(event=1)}{p_end}

{pstd}We fit a mixed effect survival model, with a random intercept and Weibull distribution, adjusting for fixed effects of {bf:x1} and {bf:x2}.{p_end}
{phang}{stata "stmixed x1 x2 || centre: , dist(weibull)":. stmixed x1 x2 || centre: , dist(weibull)}{p_end}


{title:Example 2}

{pstd}This is a simulated example dataset representing an individual patient data meta-analysis, with 15 trials and each trial recuiting 200 patients, resulting in 
3000 observations. We are interested in the pooled treatment effect, accounting for heterogeneity between trials.{p_end}

{pstd}Load dataset:{p_end}
{phang}{stata "use http://fmwww.bc.edu/repec/bocode/s/stmixed_example2":. use http://fmwww.bc.edu/repec/bocode/s/stmixed_example2}{p_end}

{pstd}stset the data:{p_end}
{phang}{stata "stset stime, f(event=1)":. stset stime, f(event=1)}{p_end}

{pstd}Create dummy variables for trial membership:{p_end}
{phang}{stata "tab trial, gen(trialvar)":. tab trial, gen(trialvar)}{p_end}

{pstd}We fit a flexible parametric model with 3 degress of freedom for the baseline, proportional trial effects with trial = 1 as the reference, 
and a random treatment effect.{p_end}
{phang}{stata "stmixed treat trialvar2-trialvar15 || trial: treat, nocons dist(fpm) df(3)":. stmixed treat trialvar2-trialvar15 || trial: treat, nocons dist(fpm) df(3)}{p_end}


{title:Author}

{pstd}Michael J. Crowther{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}UK{p_end}
{pstd}E-mail: {browse "mailto:michael.crowther@le.ac.uk":michael.crowther@le.ac.uk}.{p_end}

{phang}
Please report any errors you may find.{p_end}


{title:References}

{phang}
Crowther MJ, Riley RD, Staessen JA, Wang J, Gueyffier F, Lambert PC. Individual patient data meta-analysis of survival data using Poisson regression models. {it:BMC Med Res Methodol} 2012;{bf:12}:34.
{p_end}

{phang}
Crowther MJ, Look MP, Riley RD. Multilevel mixed effects parametric survival models using adaptive Gauss-Hermite quadrature with application to recurrent events and IPD meta-analysis. {it:Statistics in Medicine} 2014;(In Press).
{p_end}

{phang}
Liu L, Huang X. The use of Gaussian quadrature for estimation in frailty proportional hazards models. {it:Stat Med} 2008;27:2665-2683.
{p_end}

{phang}
Royston  P and Lambert PC. Flexible Parametric Survival Analysis Using Stata: Beyond the Cox Model. {it:Stata Press} 2011.
{p_end}
