{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar diag" "help gvar_diag"}{...}
{vieweralsosee "gvar unitroot" "help gvar_unitroot"}{...}
{viewerjumpto "Syntax" "gvar_lags##syntax"}{...}
{viewerjumpto "Description" "gvar_lags##description"}{...}
{viewerjumpto "Remarks" "gvar_lags##remarks"}{...}
{viewerjumpto "Examples" "gvar_lags##examples"}{...}
{viewerjumpto "Stored results" "gvar_lags##results"}{...}
{viewerjumpto "Options" "gvar_lags##options"}{...}
{title:Title}

{phang}
{bf:gvar lags} {hline 2} select the lag orders of each country model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar lags} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt maxp(#)}}largest {it:p} considered.{p_end}
{synopt:{opt maxq(#)}}largest {it:q} considered.{p_end}
{synopt:{opt maxl:ag(#)}}sets both when {cmd:maxp()} and {cmd:maxq()} are not given. Default {cmd:maxlag(2)}.{p_end}
{synopt:{opt ic(string)}}{cmd:aic} or {cmd:sbc}. Default {cmd:aic}.{p_end}
{synopt:{opt psc(#)}}order of the serial-correlation F test. Default {cmd:psc(4)}.{p_end}
{synopt:{opt set}}install the selected orders in the model.{p_end}
{synopt:{opt fix:ed(p [q])}}impose these orders on every unit.{p_end}
{synopt:{opt det:ail(unit)}}print the whole criterion grid for one unit.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar lags} chooses {it:p}, the lag order of the domestic block, and
{it:q}, that of the foreign block, for each country model, by AIC or SBC over
a grid. It also reports the serial-correlation F test at each candidate so
that a criterion-optimal order that leaves obvious residual autocorrelation is
visible rather than hidden.

{pstd}
With {cmd:set} the chosen orders are written into the model. Without it the
command only reports.


{marker options}{...}
{title:Options}

{phang}
{opt maxlag(#)} the maximum order searched, default 2, or set
{opt maxp(#)} and {opt maxq(#)} separately for the domestic and foreign lags.

{pmore}
Keep these small. The GVAR lag order becomes the maximum over all units of
{it:(p, q)}, so one unit selecting {it:p} = 4 raises the companion matrix for the
whole system -- with {it:K} = 136 that is a 544 x 544 eigenvalue problem, and the
extra lags are estimated on 134 observations.

{phang}
{opt ic(string)} the information criterion. {opt psc(#)} is the order of the
serial-correlation test reported alongside, default 4, and is the more useful
guide: a criterion minimised at {it:p} = 1 while the residuals still show
autocorrelation at that order is not a lag choice you should accept.

{phang}
{opt fixed(numlist)} fixes {it:(p, q)} for every unit rather than searching -- one
or two numbers.

{phang}
{opt set} writes the selected orders into the model. Without it the command only
reports.

{phang}
{opt detail(unit)} prints the whole criterion surface for one unit, which is how
you see whether the minimum is sharp or the choice was arbitrary.

{phang}
{opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:A caution about the criteria.} The Toolbox's AIC and SBC are in
{it:levels} form, where {bf:larger is better}. GVARX reports the log-determinant
form, where smaller is better. Both are computed from the same likelihood; the
sign convention differs. This package follows the Toolbox, so the selected
order is the one with the {bf:largest} reported criterion.

{pstd}
{bf:On the demo.} The Toolbox's own demo uses AIC with maximum {it:p} = 2 and
{it:q} = 1, which is what {helpb gvar_datasets:gvar_demospec.dta} encodes.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar lags, maxlag(2) ic(aic)}
        {cmd:. gvar lags, maxp(2) maxq(1) ic(aic) set}
        {cmd:. gvar lags, detail(usa)}
        {cmd:. gvar lags, fixed(2 1) set}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar lags} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(lags)}}the selected orders, one row per unit{p_end}
{synopt:{cmd:r(grid)}}the criterion grid, with {cmd:detail()}{p_end}
{synopt:{cmd:r(ic)}}the criterion used{p_end}
{synopt:{cmd:r(maxp)}}largest p considered{p_end}
{synopt:{cmd:r(maxq)}}largest q considered{p_end}
{synopt:{cmd:r(p)}}selected p, with {cmd:fixed()}{p_end}
{synopt:{cmd:r(q)}}selected q, with {cmd:fixed()}{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:select_varxlag.m}, {it:AIC_SBC.m}, {it:Ftest_rsc.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
