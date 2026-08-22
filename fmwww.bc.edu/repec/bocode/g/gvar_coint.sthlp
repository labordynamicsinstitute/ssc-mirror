{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar lags" "help gvar_lags"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar pp" "help gvar_pp"}{...}
{vieweralsosee "gvar overid" "help gvar_overid"}{...}
{vieweralsosee "gvar unitroot" "help gvar_unitroot"}{...}
{viewerjumpto "Syntax" "gvar_coint##syntax"}{...}
{viewerjumpto "Description" "gvar_coint##description"}{...}
{viewerjumpto "Remarks" "gvar_coint##remarks"}{...}
{viewerjumpto "Examples" "gvar_coint##examples"}{...}
{viewerjumpto "Stored results" "gvar_coint##results"}{...}
{viewerjumpto "Options" "gvar_coint##options"}{...}
{title:Title}

{phang}
{bf:gvar coint} {hline 2} Johansen cointegration tests for every country model


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar coint} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt stat(string)}}{cmd:trace} or {cmd:maxeig}. Default {cmd:trace}.{p_end}
{synopt:{opt set}}install the suggested ranks in the model.{p_end}
{synopt:{opt rank(spec)}}impose ranks by hand, as {cmd:rank(usa 2 euro 2)}.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar coint} runs the Johansen trace and maximal-eigenvalue tests on each
VECMX*, using the critical values of Pesaran, Shin and Smith (2000) for
systems with I(1) weakly exogenous regressors. These are {bf:not} the standard
Johansen critical values: they are indexed by the deterministic case, by
{it:n - r}, and by {it:k}, the number of weakly exogenous variables, and the
package ships the full table.

{pstd}
With {cmd:set} the suggested ranks are installed. The Toolbox writes
{it:suggested} ranks that the user is expected to review, and so does this.


{marker options}{...}
{title:Options}

{phang}
{opt stat(trace|maxeig)} which Johansen statistic. Default {cmd:trace}.

{pmore}
The two disagree often enough to matter. The trace test is generally the more
powerful against the alternative of one more relation; the maximal-eigenvalue
test is sharper when exactly one relation is in doubt. Where they disagree, the
rank is genuinely uncertain and neither answer should be adopted silently -- which
is the case for using {opt set} deliberately rather than by default.

{phang}
{opt rank(spec)} imposes the rank by hand, globally or per unit, instead of
reading it off the test.

{phang}
{opt set} writes the selected ranks into the model, so
{helpb gvar_estimate:gvar estimate} uses them. Without it the command only
reports: the ranks in the model are unchanged.

{pmore}
Ranks chosen unit by unit will not in general reproduce someone else's published
model. {helpb gvar_setup:gvar setup}'s {opt spec()} is how you fix the whole grid
at once, and it is the only reliable route to a replication.

{phang}
{opt graph} plots each unit's statistic against its own critical value -- which
differs from row to row, because the Pesaran-Shin-Smith values depend on the
deterministic case, {it:n-r} and {it:k}.

{phang}
{opt name()} names the graph; {opt nosummary} suppresses the report.

{pmore}
A unit whose (case, {it:n-r}, {it:k}) combination lies outside the shipped
critical-value table gets a {bf:missing} rank and the command stops and names it.
It does not fall back on a fabricated zero.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:If a critical value is missing, the rank is missing.} The published table
covers {it:k} up to 8. A unit with more weakly exogenous variables than that
has no tabulated critical value, and the command reports a missing rank and
refuses to continue rather than silently treating "no critical value" as "do
not reject", which would fabricate a rank of zero. If you hit this, either
reduce the foreign block or set the ranks by hand with {cmd:rank()}.

{pstd}
{bf:Reviewing the suggestion.} Ranks near the cut-off deserve a look at
{helpb gvar_pp:gvar pp}: a cointegrating relation whose persistence profile
does not settle back to zero is not a long-run relation, whatever the trace
statistic said. Overstated rank is the usual cause.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar coint}
        {cmd:. gvar coint, stat(maxeig)}
        {cmd:. gvar coint, set}
        {cmd:. gvar coint, rank(usa 2 euro 2 china 1)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar coint} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(coint)}}the test statistics{p_end}
{synopt:{cmd:r(rank)}}the ranks, suggested or imposed{p_end}
{synopt:{cmd:r(stat)}}which statistic was used{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:cointegration_test.m}, {it:get_rank.m}; critical values from
Pesaran, Shin and Smith (2000), shipped as {cmd:the critical-value table built into the engine}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
