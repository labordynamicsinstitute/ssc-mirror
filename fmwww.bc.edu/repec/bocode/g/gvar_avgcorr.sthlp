{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar foreign" "help gvar_foreign"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{viewerjumpto "Syntax" "gvar_avgcorr##syntax"}{...}
{viewerjumpto "Description" "gvar_avgcorr##description"}{...}
{viewerjumpto "Remarks" "gvar_avgcorr##remarks"}{...}
{viewerjumpto "Examples" "gvar_avgcorr##examples"}{...}
{viewerjumpto "Stored results" "gvar_avgcorr##results"}{...}
{viewerjumpto "Options" "gvar_avgcorr##options"}{...}
{title:Title}

{phang}
{bf:gvar avgcorr} {hline 2} average pairwise cross-section correlations


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar avgcorr} [{cmd:,} {opt block(string)} {opt gr:aph} {opt name(name)} {opt nosum:mary} {opt saving(name)}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt block(string)}}which blocks to report: {cmd:levels}, {cmd:diff}, {cmd:resid}. Default all three.{p_end}
{synopt:{opt gr:aph}}scatter the residual against the level correlations.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the tables.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar avgcorr} reports, for each variable and unit, the average
correlation with the same variable in every other unit - in the levels, the
first differences and the VECMX* residuals.

{pstd}
This is the check that the foreign variables did their job. Including them
should soak up the cross-section dependence, so the residual correlations
ought to be far smaller than those of the data. If they are not, the country
models are not conditionally independent and the generalized impulse
responses are not trustworthy.


{marker options}{...}
{title:Options}

{phang}
{opt block(spec)} which block to compute the correlations over -- the levels,
the first differences, or the residuals.

{pmore}
{bf:The comparison is the point.} Including the foreign variables is what soaks up
the cross-section dependence that would otherwise invalidate estimating each
country model separately. So the number to look at is not either level but the
{it:fall} between them: on the shipped demo the average pairwise correlation goes
from 0.6514 in the levels to 0.0484 in the residuals. A residual correlation that
stays high means the foreign block has not done its job, and every standard error
in the model is then optimistic.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:What a good result looks like.} In the shipped demo the average pairwise
correlation falls from 0.6514 in the levels to 0.0484 in the residuals, a
reduction of about thirteen times. The bucketed distribution beneath each
table, following BGVAR's {it:avg.pair.cc}, shows how many cells fall in each
band of {it:|rho|}.

{pstd}
{bf:The graph} plots residual against level correlation with the
forty-five-degree line. Points should sit well inside it. A point on or above
the line is a series whose cross-section dependence the foreign variables
failed to absorb.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar avgcorr}
        {cmd:. gvar avgcorr, block(levels resid) graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar avgcorr} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(avgcorr)}}the correlations by variable and unit{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:avgcorrs.m}, {it:corrmat.m}; GVARX {it:averageCORgvar}; the
bucketed summary follows BGVAR {it:avg.pair.cc}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
