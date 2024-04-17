{smcl}
{* *! version 1.0.0  6feb2022}{...}
{vieweralsosee "[R] heckman" "help heckman"}{...}
{vieweralsosee "[R] xtheckman" "help xtheckman"}{...}
{viewerjumpto "Syntax" "gtsheckman##syntax"}{...}
{viewerjumpto "Description" "gtsheckman##description"}{...}
{viewerjumpto "Options" "gtsheckman##options"}{...}
{viewerjumpto "Stored results" "gtsheckman##results"}{...}
{viewerjumpto "Examples" "gtsheckman##examples"}{...}
{viewerjumpto "Author" "gtsheckman##author"}{...}
{viewerjumpto "References" "gtsheckman##references"}{...}
{title:Title}

{phang}
{* phang is short for p 4 8 2}
{bf:gtsheckman} {hline 2}  A generalized two-step Heckman selection model 


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:gtsheckman}
{depvar} 
[{it:{help varlist:indepvars}}]
{ifin}
{cmd:,}
{cmd: {opt sel:ect} (}{it:{help varlist:depvar_s}} {cmd:=}
        {it:{help varlist:varlist_s}}{cmd:)}
[{it:options}]

{phang}
As in {helpb heckman}, {it:depvar} is the dependent variable, subject to sample selection, 
{it:indepvars} is the list of independent regressors, 
{it:depvar_s} is the binary selection indicator, and 
{it:varlist_s} is the list of independent regressors in the selection equation.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :*{opt sel:ect()}}specifies the selection equation: dependent and independent variables{p_end}

{p2col:{bf:het(}{it:{help varlist:varlist}}{bf:)}}independent variables to model the variance in the selection equation{p_end}

{p2col:{bf:clp(}{it:{help varlist:varlist}}{bf:)}}independent variables to be interacted with the inverse mills ratio{p_end}

{syntab:SE/Robust}
{p2col:{bf:vce(}{it:{help vcetype:vcetype}}{bf:)}}{it:vcetype} may be {cmd:robust} or {cmd:cluster} {it:clustervar}{p_end}

{syntab:Reporting}
{p2col:{bf:lambda}}generates the (scaled) inverse mills ratio (lambda) as a variable{p_end}

{syntab:Maximize}
{p2col:{it:maximize_options}}controls the maximization process; seldom used{p_end}
{synoptline}
{pstd} *{opt sel:ect()} is required.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gtsheckman} fits regression models with selection by using Heckman's two-step consistent estimator.
It is similar to the two step consistent {helpb heckman} estimator, but allows for heteroskedasticity in the first step and a more general specification of the control function.
Moreover it provides both heteroskedastic robust inference as well as cluster robust inference. 
Therefore this command encompasses the two step consistent {helpb heckman} estimator as a special case.
The methodology was proposed and studied by Carlson and Joshi (2022).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt select(depvar_s = varlist_s)} specifies the variables for the selection equation. It is an integral part of specifying a Heckman model and is required. the selection equation should contain at least one variables that is not in the outcome equation. 
{it:depvar_s} should be coded as 0 or 1, with 0 indicating an observation not selected and 1 indicating a selected observation.

{phang}
{opt het(varlist)} specifies the independent variables in the variance function for the heteroskedastic probit estimator in the first stage. 

{phang}
{opt clp(varlist)} specifies the independent variables to be interacted with lambda (inverse mills ratio) in the control function in the second stage. 


{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the stype of standard errors reported, which includes types that are robust to some kinds of misspecification ({cmd:robust}), and that allow for intragroup correlation ({cmd:cluster} {it:clustervar}).


{dlgtab:Reporting}

{phang}
{opt lambda} generates the (scaled) inverse mills ratio as a new variable named {cmd:lambda}. The inverse mills ratio is calculated from the first stage selection equation estimates, and will be scaled by the inverse of the conditional variance estimates when the option {cmd: het()} is specified. Some post estimation commands (like {helpb margins} and {helpb predict}) will require the {cmd:lambda} option be specified.  

{dlgtab:Maximization}

{phang}
{it:maximize_options} controls the maximization process; see help {help maximize}.  Use of them is likely to be rare.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz, clear}{p_end}

{pstd}Obtain Heckman's two-step consistent estimates{p_end}
{phang2}{cmd:. gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6)}{p_end}

{pstd}Obtain Heckman's two-step consistent estimates with heteroskedastic robust standard errors{p_end}
{phang2}{cmd:. gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) vce(robust)}{p_end}

{pstd}Obtain Heckman's two-step consistent estimates with heteroskedasticity in the sample selection equation and robust standard errors{p_end}
{phang2}{cmd:. gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) het(educ kidslt6 kidsge6) vce(robust)}{p_end}

{pstd}Obtain Heckman's two-step consistent estimates with heteroskedasticity in the sample selection equation and covariance, and robust standard errors{p_end}
{phang2}{cmd:. gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) het(educ kidslt6 kidsge6) clp(educ kidslt6 kidsge6) vce(robust)}{p_end}

{pstd} Additional examples can be found in the gtsheckman_examples.do do-file. 

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gtsheckman} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_selected)}}number of selected observations{p_end}
{synopt:{cmd:e(N_nonselected)}}number of nonselected observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:gtsheckman}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}

{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}
Alyssa H. Carlson{break}Department of Economics, University of Missouri{break}
carlsonah@missouri.edu{break}{browse "https://carlsonah.mufaculty.umsystem.edu/"}

{marker references}
{title:References}

{phang}
Carlson, A. H., and Joshi, R. 2024.
Sample Selection in Linear Panel Data Models with Heterogenous Coefficents. 
{it:Journal of Applied Econometrics}
39(2):237-255. 
URL: {browse "https://doi.org/10.1002/jae.3022"}

