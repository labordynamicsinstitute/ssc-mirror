{smcl}
{* 23jul2026}{...}
{vieweralsosee "icss" "help icss"}{...}
{vieweralsosee "icss methods" "help icss_methods"}{...}
{title:Title}

{phang}
{bf:flexur} {hline 2} Flexible unit-root, stationarity and variance-break tests
for time series

{title:Description}

{pstd}
{bf:flexur} is a library of time-series tests that share a common design:
robustness to structural breaks, flexible (Fourier) deterministics, non-normal
errors (RALS augmentation) and heavy-tailed / conditionally heteroskedastic data.
Each command produces journal-style tables and plots and cross-linked help with a
companion {it:methods} page.

{pstd}
Its panel-data counterpart is the {bf:xtflexur} library.

{title:Commands}

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{syntab:Variance / volatility breaks}
{synopt:{helpb icss}}ICSS test for changes in the unconditional variance
(Sansó, Aragó & Carrion-i-Silvestre 2004): IT, {it:kappa1}, {it:kappa2}{p_end}
{syntab:Stationarity}
{synopt:{helpb covstat}}Jansson-RALS covariate stationarity test with non-normal
errors (Nazlioglu, Lee, Karul & You 2021){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Additional {bf:flexur} commands (Fourier ADF/LM, RALS ADF/LM, ...) are documented
under their own help files.

{title:Common conventions}

{phang}o Tests read the time dimension from {helpb tsset} when available.{p_end}
{phang}o Results are returned in {cmd:r()}; every reported quantity is stored for
tabulation.{p_end}
{phang}o {opt graph} draws a diagnostic figure in a clean journal scheme.{p_end}
{phang}o Each command has a companion methods page: {cmd:help} {it:cmd} {cmd:methods}.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
