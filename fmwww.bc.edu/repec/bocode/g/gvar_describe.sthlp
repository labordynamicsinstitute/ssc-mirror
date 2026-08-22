{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar report" "help gvar_report"}{...}
{viewerjumpto "Syntax" "gvar_describe##syntax"}{...}
{viewerjumpto "Description" "gvar_describe##description"}{...}
{viewerjumpto "Remarks" "gvar_describe##remarks"}{...}
{viewerjumpto "Examples" "gvar_describe##examples"}{...}
{viewerjumpto "Stored results" "gvar_describe##results"}{...}
{viewerjumpto "Options" "gvar_describe##options"}{...}
{title:Title}

{phang}
{bf:gvar describe} {hline 2} what is in memory, and the order of x(t)


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar describe} [{cmd:,} {opt ord:er} {opt var:list} {opt nosum:mary}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt ord:er}}print the numbered order of x(t).{p_end}
{synopt:{opt var:list}}print each unit's domestic and weakly exogenous blocks.{p_end}
{synopt:{opt nosum:mary}}suppress the per-unit table.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar describe} reports the dimensions of the model, how far through the
workflow you are, the per-unit specification grid and, with {cmd:order}, the
numbered ordering of the global vector {it:x(t)}.

{pstd}
That ordering is not cosmetic. It is the Cholesky ordering used by
{cmd:type(oirf)} and the block boundary used by {cmd:type(sgirf)} in
{helpb gvar_irf:gvar irf}, so every orthogonalised result depends on it.


{marker options}{...}
{title:Options}

{phang}
{opt order} prints the order of the global vector {it:x_t} -- which element is
which. Read it before writing any {opt shock()} or {opt variables()}
specification, and before interpreting any matrix returned in {cmd:r()}: the row
order of everything in the package is this order.

{phang}
{opt varlist} lists each unit's domestic block, foreign block and lag orders,
including the blanks. A unit that lacks a long rate has no {it:lr} and no
{it:lr*} anywhere downstream, and this is where you confirm that is intended
rather than a name that failed to match.

{phang}
{opt stats} adds summary statistics per series.

{phang}
{opt nosummary} suppresses the header.


{marker remarks}{...}
{title:Remarks}

{pstd}
The specification table reports {it:k} and {it:k*}, the lag orders {it:p} and
{it:q}, the deterministic case, the cointegrating rank and, once estimated,
the log likelihood. The footer gives the total rank and the implied number of
unit roots, {it:K - sum r_i}, which {helpb gvar_solve:gvar solve} checks
against the eigenvalues of the companion matrix.

{pstd}
{bf:Changing the ordering.} You do not reorder the data. Use {cmd:first()} and
{cmd:vorder()} on {helpb gvar_irf:gvar irf}, {helpb gvar_fevd:gvar fevd},
{helpb gvar_spillover:gvar spillover} or {helpb gvar_hd:gvar hd}: those permute
the system internally and map the results back to the model's own order before
reporting, so the rows you read are always in the order printed here.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar describe}
        {cmd:. gvar describe, order}
        {cmd:. gvar describe, order varlist}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar describe} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(N)}}units{p_end}
{synopt:{cmd:r(K)}}endogenous variables{p_end}
{synopt:{cmd:r(T)}}periods{p_end}
{synopt:{cmd:r(units)}}unit names{p_end}
{synopt:{cmd:r(domestic)}}domestic variable names{p_end}
{synopt:{cmd:r(global)}}global variable names{p_end}
{synopt:{cmd:r(estimated)}}1 if the country models are estimated{p_end}
{synopt:{cmd:r(solved)}}1 if the GVAR is solved{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Reporting command. The grid it prints is the Toolbox's
{it:dvflag}/{it:fvflag}/{it:gvflag} specification.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
