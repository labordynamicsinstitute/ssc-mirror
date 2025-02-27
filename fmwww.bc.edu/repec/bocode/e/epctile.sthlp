{smcl}
{* *! version 1.1.0  01jul2009}{...}
{cmd:help epctile}
{hline}

{title:Title}

{phang}
{bf:epctile} {hline 2} Estimate percentiles with standard errors


{title:Syntax}

{p 8 17 2}
{cmd:epctile}
{varname}
{ifin}
{weight}
{cmd:, }{cmdab:p:ercentiles(}{it:numlist}{cmd:)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt p:ercentiles(numlist)}}estimate percentiles corresponding
        to the specified percentages{p_end}
{synopt:{opt svy}}respect survey settings{p_end}
{synopt:{cmd:subpop([}{varlist}{cmd:] [}{help if}{cmd:])}}restrict estimation to a subpopulation
        (domain){p_end}
{synopt:{opt over(varlist)}}estimate percentiles separately within
        the groups of values identified by {varlist}{p_end}
{synopt:{opt L:evel(#)}}change the confidence level to be used in CI reporting{p_end}
{synopt:{opt spec:label}}use levels of the {cmd:over(}{varlist}{cmd:)}
        groups sto label the estimation results{p_end}
{synopt:{opt val:uemask(string)}}use the value mask to label the estimation results{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:pweight}s, {cmd:fweight}s and {cmd:iweight}s are allowed; see {help weight}.{p_end}


{title:Description}

{pstd}
{cmd:epctile} estimates percentiles at given levels and computes
appropriate standard errors. {help svy} settings are partially supported:
the user needs to specify {cmd:svy} option to invoke appropriate
variance estimation methods.


{title:Options}

{dlgtab:Main}


{phang}
{opt p:ercentiles(numlist)} provides the list of percentages at which
the percentiles are to be estimated. The numbers must be strictly between 0 and 100.

{phang}
{opt over(varlist)} requests to estimate percentiles separately within
the groups of values identified by {varlist}.

{dlgtab:Survey settings}

{phang}
{opt svy} instructs to respect survey settings. The point estimates will be computed
using the appropriate weights, and the variance estimates will be obtained
via a call with {help svy} prefix. If a specific variance estimation
method needs to be used, it must be specified with the design using
{help svyset}.{p_end}

{phang}
{cmd:subpop([}{varlist}{cmd:] [}{help if}{cmd:])} restricts estimation to a subpopulation
(domain). At least one of {varlist} and {help if} conditions must be specified.{p_end}

{dlgtab:Reporting and formatting}

{phang}
{opt L:evel(#)} changes the confidence level to be used in CI reporting. The default
is the system level, which is usually 95%.{p_end}

{phang}
{opt spec:label} requests to use levels of the {cmd:over(}{varlist}{cmd:)}
groups rather than {cmd:_subpop} prefix to label the estimation results{p_end}

{phang}
{opt val:uemask(string)} requests to use the value mask to label the estimation results.
The trailing characters in the mask will be replaced by the
actual levels. Thus a good mask will look like {cmd:valuemask(}{it:00000}{cmd:)}.{p_end}


{title:Examples}

{phang}{cmd:. use adept_2002, clear}

{phang}{cmd:. svyset mesto [pw=hhw], strata(stratum)}

{phang}{cmd:. epctile income, p( 5 10 25 50 75 90 95 ) over( obraz ) svy}

{phang}{cmd:. epctile income, p(5 10 25 50 75 90 95) over(pol obraz) svy speclab valuemask( "00000")}


{title:Also see}


{psee}
{space 2}Francisco, C A, and Fuller, W A (1991). Quantile estimation
with a complex survey design. {it:The Annals of Statistics}, {bf:19} (1),
454--469. {browse "http://www.jstor.org/stable/2241867":JSTOR link}.

{psee}
{space 2}Help:  {help pctile}, {help svy}
{p_end}