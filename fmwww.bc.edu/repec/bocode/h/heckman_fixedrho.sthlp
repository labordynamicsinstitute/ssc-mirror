{smcl}
{* *! version 1  15March2018}{...}
{cmd:help heckman_fixedrho}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{cmd:heckman_fixedrho} {hline 2}}A linear regression with sample selection that allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:heckman_fixedrho} {depvar} {indepvars} {ifin} {cmd:,}
{opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}
[{cmd:,} {opth off:set(varname)} {opt nocon:stant}]{cmd:)} {opt rho}{cmd:(}{it:rho_value}{cmd:)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Model}
{p2coldent :* {opt sel:ect()}}specify selection equation:  dependent and independent variables; whether to have constant term and offset variable{p_end}
{p2coldent :* {opt rho(#)}}specify the value of "rho" to be used{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt r:obust}, {opt cl:uster} {it:clustvar}, {cmd:opg}, {opt boot:strap}, or
{opt jack:knife}{p_end}

{syntab :Reporting}
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab :Maximization}
{synopt :{it:{help heckman_fixedrho##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt select()} and {opt rho()} are required. Note that, unlike {cmd:heckman}, {it:depvar_s} = must be specified. 

{p 4 6 2}{cmd:bootstrap}, {cmd:by}, {cmd:jackknife}, {cmd:rolling},
{cmd:statsby}, and {cmd:svy} are allowed; see {help prefix}.{p_end}
{p 4 6 2}
{opt vce()},
{opt first},



{title:Description}

{pstd}
{cmd:heckman_fixedrho} This is a modification of Stata's {cmd:heckman} that allows the user to specify the value of "rho," the correlation between the unobservables. For more details on {cmd:heckman}, see {manhelp heckman R}.


{title:Options}

{dlgtab:Model}

{phang}
{opt select(...)} specifies the variables and options for the
selection equation.  It is an integral part of specifying a selection model
and is required.  

{pmore}
{it:depvar_s} should be coded as 0 or 1, 0 indicating an
observation not selected and 1 indicating a selected observation.

{phang}
{opt rho(#)} specifies the correlation between the unobservables in the selection and outcome
equations. It is required and must take a value between -1 and 1.   


{dlgtab:SE/Robust}

INCLUDE help vce_asymptall

{dlgtab:Reporting}

{phang}
{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.


{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}: {opt dif:ficult}, {opt tech:nique(algorithm_spec)},
{opt iter:ate(#)}, [{cmdab:no:}]{opt lo:g}, {opt tr:ace},
{opt grad:ient}, {opt showstep},
{opt hess:ian}, {opt showtol:erance},
{opt tol:erance(#)}, {opt ltol:erance(#)},
{opt nrtol:erance(#)}, {opt nonrtol:erance},
{opt from(init_specs)}; see {manhelp maximize R}.  These options are seldom
used.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz}{p_end}
{phang2}{cmd:. gen agesq = age^2}{p_end}
{phang2}{cmd:. gen child = kidslt6 + kidsge6}{p_end}

{pstd}Fit a regression with sample selection and specify the value of rho to be -.7{p_end}
{phang2}{cmd:. heckman_fixedrho  lwage educ exper expersq city,sel(inlf= age  agesq nwifeinc  child educ) rho(-.7)}{p_end}

{pstd}Compare with the output from {cmd:heckman}{p_end}
{phang2}{cmd:. heckman  lwage educ exper expersq city,sel(inlf= age  agesq faminc  child educ)}{p_end}
{phang2}{cmd:. heckman_fixedrho  lwage educ exper expersq city,sel(inlf= age  agesq nwifeinc  child educ) rho(-.8)}
{p_end}

{pstd}Technical note: Even when {cmd:heckman_fixedrho} is provided with the value of "rho" found by {cmd:heckman}, the results may differ between these two commands. The difference is due to the maximization procedures.{p_end}


{title:Saved results}

{pstd}
{cmd:heckman_fixedrho} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{title:Author}

	Jonathan Cook, jacook@uci.edu

{title:References}

{phang}
Cook, J., N. Newberger, and J. Lee. 2020. On identification and estimation of Heckman models. {it:Working paper}. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727":https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727}

	