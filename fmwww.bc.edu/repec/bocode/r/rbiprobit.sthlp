{smcl}
{* *! version 1.1.0: 18apr2022}{...}
{viewerjumpto "Syntax" "rbiprobit##syntax"}{...}
{viewerjumpto "Description" "rbiprobit##description"}{...}
{viewerjumpto "Options" "rbiprobit##options"}{...}
{viewerjumpto "Examples" "rbiprobit##examples"}{...}
{viewerjumpto "Saved results" "rbiprobit##results"}{...}
{viewerjumpto "References" "rbiprobit##references"}{...}
{vieweralsosee "rbiprobit postestimation" "help rbiprobit postestimation"}{...}
{hline}
{hi:help rbiprobit}{right:{browse "https://github.com/cobanomics/rbiprobit":github.com/cobanomics/rbiprobit}}
{hline}
{right:version 1.1.0}

{title:Title}

{p2colset 5 18 18 2}{...}
{p2col: {cmd:rbiprobit} {hline 2}}Recursive bivariate probit regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p2colset 5 15 25 0}{...}
{p2col: {cmd:rbiprobit}} {it:{help depvar:depvar}} [{cmd:=}] [{indepvars}] {ifin} 
	[{it:{help rbiprobit##weight:weight}}]
	{cmd:,} 
	{cmdab:endog:enous( }{help depvar:{it:depvar}_en} [{cmd:=}] 
	[{help indepvars:{it:indepvars}_en}]
	[, {help rbiprobit##enopts:{it:enopts}}]{cmd: )} 
	[{help rbiprobit##opts:{it:options}}]
{p2colreset}{...}

{synoptset 28 tabbed}{...}
{marker opts}{col 5}{help rbiprobit##options:{it:options}}{col 35}Description
{synoptline}
{syntab:Model}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opt off:set(varname)}}offset variable for outcome equation{p_end}
{synopt :{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synopt:{opt col:linear}}keep collinear variables{p_end}

{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt r:obust}, {opt cl:uster} {it:clustvar}, {opt opg},
{opt boot:strap}, or {opt jack:knife}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt lrmodel}}perform likelihood-ratio model test instead of the default Wald test{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{it:{help rbiprobit##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Maximization}
{synopt :{it:{help rbiprobit##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}

INCLUDE help shortdes-coeflegend
{synoptline}
{p2colreset}{...}

{synoptset 28 tabbed}{...}
{marker enopts}{col 5}{help rbiprobit##options:{it:enopts}}{col 35}Description
{synoptline}
{syntab:Model}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opt off:set(varname)}}offset variable for treatment equation{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
	{it:indepvars} and {it:indepvars}_en may contain factor variables; see {help fvvarlist}.
	{p_end}
{p 4 6 2}
	{it:depvar}, {it:depvar}_en, {it:indepvars}, and {it:indepvars}_en may contain 
	time-series operators; see {help tsvarlist}.
	{p_end}
{p 4 6 2}
	{opt bootstrap}, {opt jackknife}, and {opt svy} are allowed; see {help prefix}.
	{p_end}
{p 4 6 2}
	Weights are not allowed with the {helpb bootstrap} prefix.
	{p_end}
{p 4 6 2}
	{opt vce()}, {cmd:lrmodel}, and weights are not allowed with the {helpb svy} prefix.
	{p_end}
{marker weight}{...}
{p 4 6 2}
	{opt pweight}s, {opt fweight}s, and {opt iweight}s are allowed; see {help weight}.
	{p_end}
{p 4 6 2}
	{opt coeflegend} does not appear in the dialog box.
	{p_end}
{p 4 6 2}
	See {help rbiprobit postestimation:{bf:rbiprobit postestimation}} for features available after estimation.
	{p_end}


{marker description}{...}
{title:Description}

{pstd}
	{cmd:rbiprobit} is a user-written command that fits a recursive bivariate
	probit regression using maximum likelihood estimation. It is
	implemented as an {cmd:lf1 ml} evaluator. The model involves an outcome equation with 
	the dependent variable {it:depvar} and a treatment equation with the dependent
	variable {it:depvar}_en. Both dependent variables {it:depvar} and {it:depvar}_en have to 
	be binary and coded as 0/1 variables.

{pstd}
	{cmd:rbiprobit} automatically adds the treatment
	variable {it:depvar}_en as an independent variable on the right-hand side of the outcome
	equation. The independent variables in {it:indepvars} and {it:indepvars}_en may be different
	or identical. {cmd:rbiprobit} is limited to a recursive model with two equations.

	
{marker options}{...}
{title:Options}

{dlgtab:Model}
{phang}
	{opt noconstant}; see {helpb estimation options##noconstant:[R] estimation options}.

{phang}
	{opth offset(varname)}, {opt constraints(constraints)} and {opt collinear}; see 
	{helpb estimation options:[R] estimation options}.


{dlgtab:SE/Robust}
INCLUDE help vce_asymptall


{dlgtab:Reporting}
{phang}
	{opt level(#)}, {opt lrmodel} and {opt nocnsreport}; see {helpb estimation options:[R] estimation options}.

INCLUDE help displayopts_list


{marker maximize_options}{...}
{dlgtab:Maximization}
{phang}
	{it:maximize_options}: {opt dif:ficult}, {opth tech:nique(maximize##algorithm_spec:algorithm_spec)},
	{opt iter:ate(#)}, [{cmdab:no:}]{opt lo:g}, {opt tr:ace}, {opt grad:ient}, {opt showstep}, 
	{opt hess:ian}, {opt showtol:erance}, {opt tol:erance(#)}, {opt ltol:erance(#)}, 
	{opt nrtol:erance(#)}, {opt nonrtol:erance}, and {opt from(init_specs)}; 
	see {manhelp maximize R}.  These options are seldom used.

{pmore}
	Setting the optimization type to {cmd:technique(bhhh)} resets the default {it:vcetype} to {cmd:vce(opg)}.

{pstd}
	The following option is available with {opt rbiprobit} but is not shown in the dialog box:

{phang}
	{opt coeflegend}; see {helpb estimation options##coeflegend:[R] estimation options}.
	 
	 
{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse class10}{p_end}

{pstd}Recursive bivariate probit regression{p_end}
{phang2}{cmd:. rbiprobit graduate = income i.roommate i.hsgpagrp,}
		{cmd: endog(program = i.campus i.scholar income i.hsgpagrp)}
{p_end}

{pstd}Recursive bivariate probit regression with robust standard errors{p_end}
{phang2}{cmd:. rbiprobit graduate = income i.roommate i.hsgpagrp,}
		{cmd: endog(program = i.campus i.scholar income i.hsgpagrp) vce(robust)}
{p_end}
			
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rbiprobit} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary parameters{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model ({cmd:lrmodel} only){p_end}
{synopt:{cmd:e(ll_c)}}log likelihood, comparison model{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2_c)}}chi-squared for comparison test{p_end}
{synopt:{cmd:e(p)}}p-value for model test{p_end}
{synopt:{cmd:e(rho)}}rho{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(rank0)}}rank of {cmd:e(V)} for constant-only model{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:rbiprobit}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variables{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(offset1)}}offset for outcome equation{p_end}
{synopt:{cmd:e(offset2)}}offset for treatment equation{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(chi2_ct)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test corresponding to {cmd:e(chi2_c)}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:rbiprobit margdec}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {cmd:rbiprobit margdec}{p_end}
{synopt:{cmd:e(asbalanced)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{marker references}{...}
{title:References}

{phang}
	Coban, M. (2020). Redistribution Preferences, Attitudes towards Immigrants, and
	Ethnic Diversity, {it:IAB Discussion Paper} 2020/23. Available 
	from {browse "http://doku.iab.de/discussionpapers/2020/dp2320.pdf"}
	{p_end}

{phang}
	Greene, W.H. (2018). Econometric Analysis, 8th Edition, Pearson.
	{p_end}
	
{phang}
	Hasebe, T. (2013). Marginal effects of a bivariate binary choice model, 
	{it:Economic Letters} 121(2), 
	pp. 298-301. DOI: {browse "https://doi.org/10.1016/j.econlet.2013.08.028":10.1016/j.econlet.2013.08.028} 
	{p_end}
	
{marker author}{...}
{title:Author}

{phang}Mustafa Coban{p_end}
{phang}Institute for Employment Research (Germany){p_end}

{p2col 5 20 29 2:email:}mustafa.coban@iab.de{p_end}
{p2col 5 20 29 2:github:}{browse "https://github.com/cobanomics":github.com/cobanomics}{p_end}
{p2col 5 20 29 2:webpage:}{browse "https://www.mustafacoban.de":mustafacoban.de}{p_end}


{marker also_see}{...}
{title:Also see}

{psee}
    Online: help for
    {helpb biprobit}, {helpb eprobit}

{psee}
    Packages from the SSC Archive (type {cmd:ssc describe} {it:name} for
    more information):
    {helpb bicop},
    {helpb bioprobit},
    {helpb mvprobit}
