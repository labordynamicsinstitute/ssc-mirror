{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar spillover" "help gvar_spillover"}{...}
{viewerjumpto "Syntax" "gvar_gc##syntax"}{...}
{viewerjumpto "Description" "gvar_gc##description"}{...}
{viewerjumpto "Remarks" "gvar_gc##remarks"}{...}
{viewerjumpto "Examples" "gvar_gc##examples"}{...}
{viewerjumpto "Stored results" "gvar_gc##results"}{...}
{viewerjumpto "Options" "gvar_gc##options"}{...}
{title:Title}

{phang}
{bf:gvar gc} {hline 2} Granger and instantaneous causality within a country model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar gc} {cmd:,} {opt cause(varlist)} [{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt cause(varlist)}}the variables whose lags are excluded under the null. Required.{p_end}
{synopt:{opt eff:ect(varlist)}}the equations they are excluded from. Optional; the source excludes them from every non-cause equation, which is the default here.{p_end}
{synopt:{opt u:nits(list)}}which units. Default all that have the variables.{p_end}
{synopt:{opt lags(#)}}lag order of the VAR. Default is each unit's own {it:p}.{p_end}
{synopt:{opt flags(#)}}the foreign block enters at lags 0 to {it:flags}-1. Default 3.{p_end}
{synopt:{opt vce(string)}}{cmd:oim} or {cmd:robust}. Default {cmd:oim}.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar gc} tests whether the lags of one set of a unit's own variables
enter the equations of the others, twice: once in a plain VAR of the unit's
variables and once in a VARX that carries the foreign block as exogenous
regressors. It also reports the instantaneous-causality test that accompanies
the Granger one in the source.

{pstd}
Reporting both specifications is the point. It shows whether conditioning on
the rest of the world overturns a within-country causal reading.


{marker options}{...}
{title:Options}

{phang}
{opt cause(spec)} and {opt effect(spec)} name the two sides of the hypothesis, as
{it:unit:variable} with {cmd:*} wildcards. {opt units(spec)} restricts which
units are considered.

{phang}
{opt lags(#)} the lag order of the test, and {opt flags(#)} the lags of the
foreign variables carried in the auxiliary regression. Default 3.

{phang}
{opt vce(string)} the standard errors underlying the Wald statistic.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.

{pmore}
{bf:What this does and does not say.} Granger causality here is a statement about
predictive content in the reduced form, not about transmission mechanisms. In a
GVAR every variable is connected to every other through the link matrices, so a
rejection is easy to obtain and tells you less than it appears to.
{helpb gvar_irf:gvar irf} and {helpb gvar_fevd:gvar fevd} are where magnitude and
direction live; this is a screening device.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:On effect().} The source has no such argument: it restricts the cause lags
in every equation except the cause's own, so the effect set is all non-cause
variables and the first degree of freedom follows from that. Supplying
{cmd:effect()} narrows the test and is a generalisation of the source rather
than part of it.

{pstd}
{bf:On the degrees of freedom.} The second is {it:K x obs - length(PI)}, the
{bf:system} residual count, not the single-equation one. The p-value therefore
differs from what a single-equation F would give, and that is the source's
choice, faithfully reproduced.

{pstd}
{bf:On vce().} {cmd:oim} is the reference implementation's own default and is
exact. {cmd:robust} is a standard HC0 sandwich, not a port of the
{cmd:sandwich} package that GVARX passes in, and is labelled as such in the
output.

{pstd}
{bf:What the demo shows.} Testing {it:r} to {it:y}, conditioning on the
foreign block flips the conclusion for 6 of 25 units. Several countries show
domestic interest rates Granger-causing output in a closed-economy VAR and
lose it once the rest of the world enters - the rate was proxying for global
conditions.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar gc, cause(r) effect(y)}
        {cmd:. gvar gc, cause(r) units(usa euro japan)}
        {cmd:. gvar gc, cause(eq) flags(3) vce(robust)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar gc} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(gc)}}the statistics, one row per unit{p_end}
{synopt:{cmd:r(nvar)}}rejections in the plain VAR{p_end}
{synopt:{cmd:r(nvarx)}}rejections in the VARX{p_end}
{synopt:{cmd:r(nflip)}}units where the two disagree{p_end}
{synopt:{cmd:r(nunits)}}units tested{p_end}
{synopt:{cmd:r(nskip)}}units lacking one of the variables{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
GVARX {it:.grangerGVAR}; the test itself is vars {it:causality()}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
