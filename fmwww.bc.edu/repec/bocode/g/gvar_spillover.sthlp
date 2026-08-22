{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar fevd" "help gvar_fevd"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar gc" "help gvar_gc"}{...}
{viewerjumpto "Syntax" "gvar_spillover##syntax"}{...}
{viewerjumpto "Description" "gvar_spillover##description"}{...}
{viewerjumpto "Remarks" "gvar_spillover##remarks"}{...}
{viewerjumpto "Examples" "gvar_spillover##examples"}{...}
{viewerjumpto "Stored results" "gvar_spillover##results"}{...}
{viewerjumpto "Options" "gvar_spillover##options"}{...}
{title:Title}

{phang}
{bf:gvar spillover} {hline 2} Diebold-Yilmaz connectedness


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar spillover} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt step(#)}}horizon. Default 24.{p_end}
{synopt:{opt by(string)}}{cmd:unit}, {cmd:variable} or {cmd:none}. Default {cmd:unit}.{p_end}
{synopt:{opt type(string)}}{cmd:girf}, {cmd:oirf} or {cmd:sgirf}.{p_end}
{synopt:{opt top(#)}}how many blocks to list at each end. Default 12.{p_end}
{synopt:{opt full}}also print the pairwise table, if it fits.{p_end}
{synopt:{opt first(units)}}which units lead the ordering. For {cmd:type(sgirf)} this {bf:is} the identifying assumption, and the block size is derived from it.{p_end}
{synopt:{opt vord:er(spec)}}the variable order inside each leading unit, one block per unit separated by {cmd:;}.{p_end}
{synopt:{opt vcov(string)}}{cmd:sample} keeps the estimated covariance; {cmd:blockdiag} zeroes every cross-unit covariance; {cmd:blockdiag }{it:unit} does the same but leaves one unit's cross-covariances free.{p_end}
{synopt:{opt shrink}}shrink the correlation matrix towards the identity, intensity chosen internally.{p_end}
{synopt:{opt lam:bda(#)}}set the shrinkage intensity by hand, between 0 and 1.{p_end}
{synopt:{opt gr:aph}}net-transmitter bar chart.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the tables.{p_end}
{synopt:{opt saving(name)}}save the block table.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar spillover} builds the Diebold-Yilmaz connectedness table from the
variance decomposition at a chosen horizon: how much of each block's forecast
error variance comes from the others, how much it sends, and the net
difference.

{pstd}
A 136 by 136 table is unreadable, so the result is aggregated into blocks -
by unit, which is what the empirical literature reports, or by variable.


{marker options}{...}
{title:Options}

{phang}
{opt step(#)} the horizon at which connectedness is measured. Default 24.
Diebold-Yilmaz shares are horizon-dependent and the choice is substantive, not
cosmetic: short horizons load on contemporaneous transmission, long ones on the
accumulated dynamics.

{phang}
{opt type(girf|oirf|sgirf)} the identification underlying the variance shares.

{pmore}
The generalized version is the usual choice and is what Diebold and Yilmaz
themselves use, but note its FEVD columns do not sum to one, so the shares are
row-normalised before the table is formed. That normalisation is part of the
method, not a repair.

{phang}
{opt by(spec)} aggregates the table by group -- region, income class -- instead
of reporting all {it:K} x {it:K} pairs, and {opt top(#)} lists only the largest
transmitters and receivers. Default 12.

{phang}
{opt full} prints the whole matrix rather than the summary, which is what you
want when feeding it to something else.

{phang}
{opt first(units)}, {opt vorder(spec)}, {opt vcov(spec)}, {opt shrink} and
{opt lambda(#)} as in {helpb gvar_irf:gvar irf}.

{phang}
{opt rolling(#)} and {opt every(#)} compute the index over rolling windows of
{it:#} observations, every {it:#} periods, which is how the time-varying
connectedness plots in that literature are produced. A window shorter than the
model needs will produce numbers that mean nothing; the command reports how many
windows were explosive rather than averaging them in silently.

{phang}
{opt network} draws a directed network diagram instead of the table, and
{opt threshold(#)} suppresses edges below a share, without which the diagram is
a solid block of arrows.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:How the aggregation works.} The rows are normalised to 100 first and then
summed within blocks, which is the convention in Diebold and Yilmaz (2014) and
in BGVAR. Rows of the block table are averaged over the members of the
receiving block, so a row still sums to 100 rather than to 100 times its size.

{pstd}
{bf:The total connectedness index} is the average share of forecast error
variance that comes from other blocks. Higher means a more interconnected
system. It depends on the horizon and on the aggregation, so quote both.

{pstd}
{bf:NET is the number to read.} A positive net value marks a block that
exports more variance than it imports - a transmitter. The ranking is by net,
largest transmitters first.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar spillover, step(24) by(unit)}
        {cmd:. gvar spillover, step(24) by(variable) full}
        {cmd:. gvar spillover, step(12) by(unit) graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar spillover} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(spillover)}}the block table{p_end}
{synopt:{cmd:r(from)}}variance imported{p_end}
{synopt:{cmd:r(to)}}variance exported{p_end}
{synopt:{cmd:r(net)}}to minus from{p_end}
{synopt:{cmd:r(tci)}}total connectedness index{p_end}
{synopt:{cmd:r(step)}}the horizon{p_end}
{synopt:{cmd:r(by)}}the aggregation used{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Built from {it:fevd.m}; connectedness follows BGVAR {it:conn} and Diebold and
Yilmaz (2009, 2014).

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
