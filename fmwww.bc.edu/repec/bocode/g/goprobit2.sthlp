{smcl}
{* *! version 1.0.0  17feb2025}{...}
{p2colset 6 19 25 2}{...}
{p2col:{bf:goprobit2} {hline 2}}Generalized ordered probit regression{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:goprobit2}
{depvar}
[{indepvars}]
{ifin}
[{it:{help weight}}]
{bind:[{cmd:,} {it:options}]}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Model}
{synopt :{opth dist:ribution(goprobit2##distname:distname)}}specify distribution for link function; default is {opt dist:ribution(normal)}{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim}, {opt opg},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, or
   {opt jack:knife}{p_end}

{syntab :Maximization}
{synopt :{it:{help goprobit2##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed;
see {help weight}.{p_end}


{marker distname}{...}
{synoptset 32 tabbed}{...}
{synopthdr:distname}
{synoptline}
{syntab :SGT family}
{synopt :{opt normal}}normal distribution; the default{p_end}
{synopt :{opt snormal}}skewed normal distribution{p_end}
{synopt :{opt laplace}}Laplace distribution{p_end}
{synopt :{opt slaplace}}skewed Laplace distribution{p_end}
{synopt :{opt ged}}generalized error distribution{p_end}
{synopt :{opt sged}}skewed generalized error distribution{p_end}
{synopt :{opt t}}t distribution{p_end}
{synopt :{opt st}}skewed t distribution{p_end}
{synopt :{opt gt}}generalized t distribution{p_end}
{synopt :{opt sgt}}skewed generalized t distribution{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{opt goprobit2} is a community-contributed module which fits ordered response 
regression models of ordinal variable {depvar} on the independent variables 
{indepvars}. It extends {opt oprobit} by offering a variety of link functions based
 on the SGT family of statistical distributions.


{title:Options}

{dlgtab:Model}

{phang}
{opth dist:ribution(goprobit2##distname:distname)} specifies the distribution of 
the link function.  This means the CDF of {it:distname} is the link function; 
with {opt dist(normal)}, the default, the Normal CDF is used, producing the same 
results as {bf:oprobit}.

{dlgtab:SE/Robust}

INCLUDE help vce_asymptall

{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}:
{opt dif:ficult},
{opth tech:nique(maximize##algorithm_spec:algorithm_spec)},
{opt iter:ate(#)}, [{cmd:no}]{opt log}, {opt tr:ace}, 
{opt grad:ient}, {opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)}, 
{opt nrtol:erance(#)}, and
{opt nonrtol:erance}; see {helpb maximize:[R] Maximize}.
These options are seldom used.


{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse fullauto}{p_end}

{pstd}Ordered response regression with Skewed Generalized t CDF link function{p_end}
{phang2}{cmd:. oprobit rep77 foreign length mpg, dist(sgt)}{p_end}

    {hline}


{title:Stored results}

{pstd}
{cmd:goprobit2} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_cat)}}number of categories{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}{it:p}-value for model test{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:goprobit2}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(distribution)}}distribution entered in {opt distribution(distname)}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                     maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(cat)}}category values{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Future Features}

{pstd}
This vesion of {bf:goprobit2} is fully functional, although not yet optimized in 
terms of computational performance.  A future version will prioritize such 
optimization to make this program tractable with big data.  If you would like to 
help, please contact the author.
	

{title:Authors}

{pstd}
Jacob Triplett authored this program with help from authors of a paper describing this estimator (see Johnston, McDonald & Quist (2019), referenced below).  Please
contact Jacob with questions or comments.

{phang}Jacob Triplett{p_end}
{phang}The University of North Carolina{p_end}
{phang}Kenan-Flagler Business School{p_end}
{phang}jacob_triplett@kenan-flagler.unc.edu{p_end}


{title:References}

{phang}
Johnston, C., McDonald, J., & Quist, K. (2019). A generalized ordered Probit model. Communications in Statistics - Theory and Methods, 49(7), 1712–1729. https://doi.org/10.1080/03610926.2019.1565780

{phang}Related software packages include:{p_end}
{phang2}{bf:{stata help oprobit: oprobit}} {space 1}(Stata){p_end}
{phang2}{bf:{stata help ologit: ologit}} {space 2}(Stata){p_end}
{phang2}{bf:{stata ssc describe goprobit: goprobit}} (Community-contributed){p_end}
{phang2}{bf:{stata ssc describe gologit: gologit}} {space 1}(Community-contributed){p_end}
{phang2}{bf:{stata ssc describe gologit2: gologit2}} (Community-contributed){p_end}

