{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpanic" "help xtpanic"}{...}
{vieweralsosee "xtpanic methods" "help xtpanic_methods"}{...}
{vieweralsosee "flexur (time series)" "help flexur"}{...}
{title:Title}

{phang}
{bf:xtflexur} {hline 2} Factor-augmented, break- and Fourier-robust panel
time-series tests

{title:Description}

{pstd}
{bf:xtflexur} is a library of second-generation panel time-series tests built on a
common {it:factor-extraction} engine (the PANIC approach of Bai & Ng): common
factors are estimated by principal components and removed, so the tests are robust
to strong cross-sectional dependence of an unknown form. Commands read the panel
from {helpb xtset}, return everything in {cmd:r()}, and ship cross-linked help with
a companion {it:methods} page.

{pstd}
Its single-series counterpart is the {helpb flexur:flexur} library.

{title:Commands}

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{syntab:Panel unit root (factor-based)}
{synopt:{helpb xtpanic}}PANIC panel unit root test (Bai & Ng 2004): tests the
idiosyncratic component after removing common factors{p_end}
{synopt:{helpb xtfpanic}}Fourier-PANIC: PANIC with smooth (Fourier) structural
breaks and common factors (Nazlioglu et al. 2023){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Further {bf:xtflexur} commands (PANIC with sharp/smooth breaks, panel stationarity
combination tests, factor-corrected panel causality) build on the same factor
engine and are documented under their own help files.

{title:Common conventions}

{phang}o Panel and time dimensions are read from {helpb xtset}; a strongly balanced
panel is required.{p_end}
{phang}o Every reported quantity is stored in {cmd:r()} for tabulation.{p_end}
{phang}o Each command has a companion methods page: {cmd:help} {it:cmd} {cmd:methods}.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
