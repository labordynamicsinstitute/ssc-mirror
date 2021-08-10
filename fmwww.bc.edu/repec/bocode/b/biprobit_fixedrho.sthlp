{smcl}
{* documented: April2019}{...}
{cmd:help biprobit_fixedrho}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:biprobit_fixedrho} {hline 2}} Bivariate probit regression that allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:biprobit_fixedrho}
{it:depvar_1} {it:varlist_1} {ifin}
{cmd:,} {opt eq2}{cmd:(}{it:depvar_2} {cmd:=} {it:varlist_2}{cmd:)} [{it:{help biprobit_fixedrho##biprobit_fixedrhooptions:biprobit_fixedrho_options}}]


{marker biprobit_fixedrhooptions}{...}
{synoptset 27 tabbed}{...}
{synopthdr :biprobit_fixedrho_options}
{synoptline}
{syntab:Main}
{p2coldent :* {opt eq2()}}specify second probit:  dependent and independent variables{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}


{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt r:obust}, {opt cl:uster} {it:clustvar}, {cmd:opg}, {opt boot:strap}, or
{opt jack:knife}{p_end}

{syntab :Maximization}
{synopt :{it:{help biprobit_fixedrho##maximize_options:maximize_options}}}control the maximization process{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt eq2()} is required. The full specification is{p_end}
{p 10 10 2}
{opt eq2}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}{cmd:)}
{p_end}
{p 4 6 2}{it:indepvars} may contain factor variables; see {helpb fvvarlist}.
{p_end}
{p 4 6 2}{it:depvar} and {it:indepvars} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{opt bootstrap}, {opt by}, {opt jackknife}, {opt nestreg},
{opt rolling}, {opt statsby}, {opt stepwise}, and {opt svy}
are allowed; see {help prefix}.
{p_end}


{title:Description}

{pstd}
{cmd:biprobit_fixedrho} Bivariate probit regression that allows the user to specify the value of "rho". This command is based on {cmd:biprobit}. For more details on {cmd:biprobit}, see {manhelp biprobit R}.
 
 
{title:Options}

{dlgtab:Main}

{phang}
{opt eq2()} specify the second equation:  dependent and independent variables. This option is required.{p_end}

{phang}
{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported, which
includes types that are derived from asymptotic theory, that are robust to
some kinds of misspecification, that allow for intragroup correlation, and
that use bootstrap or jackknife methods; see
{helpb vce_option:[R] {it:vce_option}}.
{p_end}

{pmore}
{cmd:vce(conventional)}, the default, uses the conventionally derived variance
estimators for first and second part models.


{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}:
{opt dif:ficult}, {opt tech:nique(algorithm_spec)},
{opt iter:ate(#)}, [{cmd:{ul:no}}]{opt lo:g}, {opt tr:ace}, 
{opt grad:ient}, {opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)},
{opt nonrtol:erance},
{opt from(init_specs)}; see {manhelp maximize R}.  These options are seldom
used.

 
{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse school}{p_end}

{pstd}Estimation{p_end}
{phang2}{cmd:.biprobit_fixedrho private logptax loginc years vote, eq2(vote=logptax loginc years) rho(0)}{p_end}

{pstd}Compare with biprobit{p_end}
{phang2}{cmd:.biprobit (private = years vote) (vote=logptax loginc years)}{p_end}
{phang2}{cmd:.biprobit_fixedrho private years vote, eq2(vote=logptax loginc years) rho(-.7277168)}{p_end}
{pstd}Note that the estimates differ because of differences in the maximization procedure{p_end}


{title:Author}

	Jonathan Cook, jacook@uci.edu
	
{title:References}

{phang}
Cook, J., N. Newberger, and J. Lee. 2020. On identification and estimation of Heckman models. {it:Working paper}. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727":https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727}

