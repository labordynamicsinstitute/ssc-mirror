{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar import" "help gvar_import"}{...}
{title:Title}

{phang}
{bf:gvar datasets} {hline 2} the example data shipped with the package


{title:Description}

{pstd}
The package ships the data needed to reproduce the GVAR Toolbox's own demo,
converted from the original workbook and R sources. Every example in the help
files runs on it.


{title:The main panels}

{synoptset 24 tabbed}{...}
{synopt:{cmd:gvar_demo26.dta}}33 countries with the eight euro-area members
aggregated into a single {cmd:euro} unit, giving 26 units and K = 136;
quarterly 1979Q2-2013Q1, six domestic variables ({cmd:y Dp eq ep r lr}) and
three commodity prices ({cmd:poil pmat pmetal}). This is the Toolbox's own
demo model, and the panel every example in this package uses.{p_end}
{synoptline}


{title:Specification and weights}

{synoptset 24 tabbed}{...}
{synopt:{cmd:gvar_demospec.dta}}the full specification grid recovered from the
Toolbox workbook: per unit and variable, the {cmd:dv}, {cmd:fv} and {cmd:gv}
flags, the lag orders {cmd:p} and {cmd:q}, the deterministic {cmd:case} and
the published {cmd:rank}.{p_end}
{synopt:{cmd:gvar_flows.dta}}bilateral trade flows by year, in long form
({cmd:home}, {cmd:partner}, {cmd:year}, {cmd:trade}).{p_end}
{synopt:{cmd:gvar_demoagg.dta}}the crosswalk mapping the eight euro-area
members onto the {cmd:euro} aggregate. Required: the aggregate never appears
in the raw flow data.{p_end}
{synoptline}


{title:Critical values are in the code, not in a dataset}

{pstd}
The 648 Pesaran-Shin-Smith (2000) critical values used by
{helpb gvar_coint:gvar coint} -- for the Johansen tests with I(1) weakly
exogenous regressors, indexed by deterministic case, {it:n - r} and {it:k} --
are held in the Mata engine rather than in a shipped dataset. They are
constants, so nothing is gained by putting them in a file that can go missing:
{cmd:gvar coint} used to refuse with {bf:r(601)} if it did.

{pstd}
{bf:No dataset is installed with the package.} SSC caps a package description
at 100 lines, and listing 26 data files put this package at 114. Fetch them
instead, with one command:

{phang2}{cmd:. gvar getdata, list}{p_end}
{phang2}{cmd:. gvar getdata demo, from(ssc) pkg(}{it:package}{cmd:)}{p_end}

{pstd}
{bf:Nothing was dropped.} Every dataset described on this page is still
available -- it arrives when you ask rather than at install time. See
{helpb gvar_getdata:gvar getdata}, which also records why the arrangement is
this way and quotes the archive maintainer's own remedy.


{title:Reproducing the demo}

        {cmd:. use gvar_demo26}
        {cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) ///}
                {cmd:global(poil pmat pmetal) gendog(poil=usa pmat=usa pmetal=usa) ///}
                {cmd:spec(gvar_demospec.dta)}
        {cmd:. gvar weights using gvar_flows.dta, flow(trade) source(partner) ///}
                {cmd:destination(home) year(year) years(2009 2011) type(1) ///}
                {cmd:map(gvar_demoagg.dta)}
        {cmd:. gvar foreign}
        {cmd:. gvar estimate, vce(nwest)}
        {cmd:. gvar solve}

{pstd}
This reproduces the Toolbox's demo settings: fixed trade weights averaged over
2009-2011, AIC lag selection with maximum {it:p} = 2 and {it:q} = 1,
deterministic case 4 throughout, and the published cointegrating ranks. The
solved model is stable with 69 unit roots against K = 136 and a total rank of
66.


{title:A note on the source data}

{pstd}
The original workbook uses {cmd:123456789} as its missing-value marker. That
is converted to Stata missing on import. Read as data it produces constant
columns, singular residual covariances and fabricated test results, so if you
build your own panel from the same workbook, check for it.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
