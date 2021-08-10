{smcl}
{* documented: April2019}{...}
{cmd:help etregress_fixedrho}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :etregress_fixedrho {hline 2}}Linear regression with endogenous treatment effects that allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:etregress_fixedrho}
{it:depvar_1} {it:varlist_1} {ifin}
{cmd:,} {opt treat}{cmd:(}{it:depvar_2} {cmd:=} {it:varlist_2}{cmd:)} {opt rho}{cmd:(}{it:rho_value}{cmd:)}  [{it:{help etregress_fixedrho##etregress_fixedrhooptions:etregress_fixedrho_options}}]


{marker etregress_fixedrhooptions}{...}
{synoptset 27 tabbed}{...}
{synopthdr :etregress_fixedrho_options}
{synoptline}
{syntab:Main}
{p2coldent :* {opt treat()}}specify treatment probit:  dependent and independent variables{p_end}
{p2coldent :* {opt rho()}}specify the correlation between the unobservables{p_end}
{synopt :{opt po:utcomes}}use potential-outcome model with separate
                                  treatment and control group variance{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
{opt r:obust}, {opt cl:uster} {it:clustvar}, {cmd:opg}, {opt boot:strap}, or
{opt jack:knife}{p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab :Maximization}
{synopt :{it:{help etregress_fixedrho##maximize_options:maximize_options}}}control the maximization process{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* Both {opt treat()} and {opt rho()} are required. The full specification for {opt treat()} is{p_end}
{p 10 10 2}
{opt treat}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}{cmd:)}
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
{cmd:etregress_fixedrho} Linear regression with endogenous treatment effects that allows the user to specify the value of "rho". This command is based on the full maximum likelihood version of {cmd:etregress}. For more details on {cmd:etregress},
 see {manhelp etregress R}.
 
 
{title:Options}

{dlgtab:Main}

{phang}
{opt treat()} specifies the second equation:  dependent and independent variables. This option is required. depvar_s should be coded as 0 or 1, 0 indicating an observation not
        selected and 1 indicating a selected observation.{p_end}

{phang}
{opt rho(#)} specifies the correlation between the unobservables in the
        selection and outcome equations. It is required and must take a value
        between -1 and 1.{p_end}

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
{phang2}{cmd:. webuse union3}{p_end}

{pstd}Estimation{p_end}
{phang2}{cmd:. etregress_fixedrho wage age grade smsa black tenure union, treat(union = south black tenure) rho(-.5746478)}{p_end}

{pstd}Compare with etregress (full ML estimation){p_end}
{phang2}{cmd:. etregress wage age grade smsa black tenure, treat(union = south black tenure)}{p_end}

{pstd}Technical note: Even when {cmd:etregress_fixedrho} is provided with the value of
    "rho" found by {cmd:etregress}, the results may differ between these two
    commands. The difference is due to the maximization procedures.{p_end}


{title:Author}

	Jonathan Cook, jacook@uci.edu
	
{title:References}

{phang}
Cook, J., N. Newberger, and J. Lee. 2020. On identification and estimation of Heckman models. {it:Working paper}. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727":https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3639727}

	