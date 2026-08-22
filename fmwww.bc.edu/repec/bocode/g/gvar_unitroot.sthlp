{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar coint" "help gvar_coint"}{...}
{vieweralsosee "gvar wetest" "help gvar_wetest"}{...}
{vieweralsosee "gvar lags" "help gvar_lags"}{...}
{viewerjumpto "Syntax" "gvar_unitroot##syntax"}{...}
{viewerjumpto "Description" "gvar_unitroot##description"}{...}
{viewerjumpto "Remarks" "gvar_unitroot##remarks"}{...}
{viewerjumpto "Examples" "gvar_unitroot##examples"}{...}
{viewerjumpto "Stored results" "gvar_unitroot##results"}{...}
{viewerjumpto "Options" "gvar_unitroot##options"}{...}
{title:Title}

{phang}
{bf:gvar unitroot} {hline 2} unit root tests on the domestic and foreign variables


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar unitroot} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt maxl:ag(#)}}maximum lag order for the augmentation. Default {cmd:maxlag(4)}.{p_end}
{synopt:{opt ic(string)}}{cmd:aic} or {cmd:sbc} for choosing the augmentation order.{p_end}
{synopt:{opt tests(list)}}which tests to run: {cmd:adf}, {cmd:ws}, {cmd:gls}, {cmd:kpss}, {cmd:pp}. Default is all.{p_end}
{synopt:{opt blocks(list)}}{cmd:levels}, {cmd:diff}, {cmd:diff2}. Default is levels and first differences.{p_end}
{synopt:{opt dom:estic}}domestic variables only.{p_end}
{synopt:{opt for:eign}}foreign variables only.{p_end}
{synopt:{opt lev:el(#)}}significance level for the rejection marks. Default 95.{p_end}
{synopt:{opt sum:mary}}print the full per-series table rather than the counts.{p_end}
{synopt:{opt saving(name)}}save the results matrix.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar unitroot} runs the Toolbox's battery on every series in the model:
augmented Dickey-Fuller, the weighted-symmetric ADF of Park and Fuller,
ADF-GLS, KPSS and Phillips-Perron. Each is run on levels, first differences
and, where the block is requested, second differences, for both the domestic
and the foreign variables.

{pstd}
The GVAR treats the variables as I(1) and the foreign variables as I(1) and
weakly exogenous. This command is where you check the first half of that
claim; {helpb gvar_wetest:gvar wetest} checks the second.


{marker options}{...}
{title:Options}

{phang}
{opt tests(spec)} which tests to run: ADF, weighted-symmetric ADF, ADF-GLS,
KPSS, Phillips-Perron. Omitted, the standard set is run.

{pmore}
They are not interchangeable. KPSS reverses the null -- stationarity rather than a
unit root -- so a series that ADF fails to reject and KPSS also rejects is
telling you the sample is uninformative, not that the series is borderline.

{phang}
{opt maxlag(#)} the maximum augmentation lag. Default 4. {opt ic(string)}
selects the criterion used to choose within that maximum.

{phang}
{opt domestic} and {opt foreign} restrict the tests to one block or the other. In
a GVAR the foreign variables need to be I(1) for the weak-exogeneity argument to
hold, so both blocks matter and for different reasons.

{phang}
{opt blocks(spec)} groups the output.

{phang}
{opt graph}, {opt gstat(string)} and {opt gblock(#)} control the plot:
{opt gstat()} chooses which statistic is plotted and {opt gblock()} which block,
since one chart cannot carry five tests over two blocks legibly.

{phang}
{opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Reading the output.} A well-specified GVAR wants most series
non-stationary in levels and stationary in first differences. Widespread
rejection in levels is a signal that a series may be I(0) and does not belong
in a cointegrating relation; failure to reject in differences suggests I(2)
and needs attention before anything else in the workflow is meaningful.

{pstd}
{bf:On the ADF augmentation.} The Toolbox's {it:adf.m} trims one extra
observation when {it:p} = 4. That quirk is reproduced exactly so results match
published output; it is documented in the package inventory.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar unitroot}
        {cmd:. gvar unitroot, tests(adf ws) blocks(levels diff) summary}
        {cmd:. gvar unitroot, domestic maxlag(4) ic(sbc)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar unitroot} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(urt)}}the results matrix{p_end}
{synopt:{cmd:r(ic)}}the information criterion used{p_end}
{synopt:{cmd:r(maxlag)}}the maximum augmentation order{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:unitroot_tests.m}, {it:adf.m}, {it:ws.m}, {it:detrend.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
