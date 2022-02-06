{smcl}
{* *! version 1  15March2018}{...}
{cmd:help heckprobit_fixedrho}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{cmd:heckprobit_fixedrho} {hline 2}}A probit model with sample selection that allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:heckprobit_fixedrho} {depvar} {indepvars} {ifin} {cmd:,}
{opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}
[{cmd:,} {opth off:set(varname)} {opt nocon:stant}]{cmd:)}
{opt rho}{cmd:(}{it:rho_value}{cmd:)}
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
{synopt :{it:{help heckprobit_fixedrho##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt select()} and {opt rho()} are required. Note that, unlike {cmd:heckprobit}, {it:depvar_s} = must be specified. 

{p 4 6 2}{cmd:bootstrap}, {cmd:by}, {cmd:jackknife}, {cmd:rolling},
{cmd:statsby}, and {cmd:svy} are allowed; see {help prefix}.{p_end}
{p 4 6 2}
{opt vce()},
{opt first},



{title:Description}

{pstd}
{cmd:heckprobit_fixedrho} This is a modification of Stata's {cmd:heckprobit} that allows the user to specify the value of "rho," the correlation between the unobservables. For more details on {cmd:heckprobit}, see {manhelp heckprobit R}.


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
{phang2}{cmd:. webuse school}{p_end}

{pstd}Fit a probit model with sample selection and specify the value of rho to be -.7{p_end}
{phang2}{cmd:. heckprobit_fixedrho private years logptax, sel(vote=years loginc logptax) rho(-.7)}{p_end}

{pstd}Compare with the output from {cmd:heckprobit}{p_end}
{phang2}{cmd:. heckprobit private years logptax, sel(vote=years loginc logptax)}
{p_end}


{title:Saved results}

{pstd}
{cmd:heckprobit_fixedrho} saves the following in {cmd:e()}:

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

{title:Authors}

	Jonathan Cook, jacook@uci.edu
	
{title:References}

{phang}
Cook, J., N. Newberger, and J. Lee. 2020. On identification and estimation of Heckman models. {it:Working paper}. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727":https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727}

{phang}
Cook, J., N. Newberger, and J. Lee. 2021. On identification and estimation of Heckman models. {it:Stata Journal}, 21(4), p 972-998. {browse "https://doi.org/10.1177/1536867X211063149":https://doi.org/10.1177/1536867X211063149}
