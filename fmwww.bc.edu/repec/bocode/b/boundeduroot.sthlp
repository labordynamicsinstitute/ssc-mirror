{smcl}
{* *! version 1.0.0  07jul2026  Merwan Roudane}{...}
{vieweralsosee "boundeduroot mtests" "help boundeduroot_mtests"}{...}
{vieweralsosee "boundeduroot breaks" "help boundeduroot_breaks"}{...}
{vieweralsosee "boundeduroot hlt" "help boundeduroot_hlt"}{...}
{vieweralsosee "boundedur (Cavaliere-Xu 2014)" "help boundedur"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "boundeduroot##syntax"}{...}
{viewerjumpto "Description" "boundeduroot##description"}{...}
{viewerjumpto "Modules" "boundeduroot##modules"}{...}
{viewerjumpto "Remarks" "boundeduroot##remarks"}{...}
{viewerjumpto "References" "boundeduroot##references"}{...}
{viewerjumpto "Author" "boundeduroot##author"}{...}
{title:Title}

{phang}
{bf:boundeduroot} {hline 2} Unit-root and level-shift tests for bounded time series (a library)

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:boundeduroot} {it:subcommand} {varname} {ifin}{cmd:,} {it:options}

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb boundeduroot_mtests:mtests}}GLS M-tests for bounded series (Carrion-i-Silvestre & Gadea 2013){p_end}
{synopt:{helpb boundeduroot_breaks:breaks}}bounded unit-root tests with structural breaks (CSG 2016){p_end}
{synopt:{helpb boundeduroot_hlt:hlt}}bounded multiple level-shift detection, HLT (CSG 2024){p_end}
{synoptline}

{pstd}
The series must be {helpb tsset}. All modules work on a single time series (no panels).

{marker description}{...}
{title:Description}

{pstd}
{cmd:boundeduroot} is a library of unit-root and level-shift tests for {it:bounded}
time series {hline 1} series confined to an interval either by construction or by policy
(unemployment rates, budget shares, nominal interest rates, capacity-utilisation rates,
target-zone exchange rates). It is the structural-break companion to the base command
{helpb boundedur}, which implements the Cavaliere & Xu (2014) simulation-based ADF and M
tests. Where {cmd:boundedur} handles the no-break case, {cmd:boundeduroot} adds GLS
detrending, structural breaks in the mean, and multiple level-shift detection, each with
{it:bound-specific} critical values obtained by simulating a regulated (reflected)
Brownian motion.

{marker modules}{...}
{title:Modules}

{dlgtab:mtests -- GLS M-tests for bounded series (2013)}

{pstd}
{helpb boundeduroot_mtests:boundeduroot mtests} computes the MSB, MZ{sub:{&alpha}} and
MZ{sub:t} tests under three detrending schemes (OLS, GLS-ERS, GLS-BOUNDS) crossed with
parametric (spectral AR) and non-parametric (QS) long-run variance estimation {hline 1} six
configurations {hline 1} each judged against its own bound-specific simulated critical values.
Implements Carrion-i-Silvestre & Gadea (2013).

{dlgtab:breaks -- bounds and structural breaks (2016)}

{pstd}
{helpb boundeduroot_breaks:boundeduroot breaks} tests the bounded unit-root null allowing
zero, one or two breaks in the mean. Break dates are estimated by minimising the SSR of the
first-differenced model; the MSB, MZ{sub:{&alpha}}, MZ{sub:t}, variance-ratio and ADF
statistics are reported for each configuration with piecewise (segment-specific) bounded
critical values. Implements Carrion-i-Silvestre & Gadea (2016).

{dlgtab:hlt -- multiple level-shift detection (2024)}

{pstd}
{helpb boundeduroot_hlt:boundeduroot hlt} detects multiple level shifts in a bounded series,
regardless of its order of integration, using the Harvey-Leybourne-Taylor (2010) S0 and S1
statistics with bound-specific critical values. Implements Carrion-i-Silvestre & Gadea (2024),
Case A (constant boundaries).

{marker remarks}{...}
{title:Remarks}

{pstd}
All three modules retrieve their critical values by Monte Carlo simulation of a regulated
Brownian motion folded (reflected) into the estimated bounds, so they can be slow for large
{cmd:iter()}. The bound parameters are standardised as {cmd:c = (b - X0)/(s*sqrt(T))} with
{cmd:X0} the first observation and {cmd:s} the relevant long-run standard deviation, exactly
as in the source papers. Each module leaves its results in {cmd:r()} and draws a journal-style
figure unless {cmd:nograph} is specified.

{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2013. GLS-based unit root tests for bounded
processes.

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2016. Bounds, breaks and unit root tests.
{it:Journal of Time Series Analysis} 37(2): 165-181.
{browse "https://doi.org/10.1111/jtsa.12144":doi:10.1111/jtsa.12144}.

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2024. Detecting multiple level shifts in bounded
time series.

{phang}
Cavaliere, G., and F. Xu. 2014. Testing for unit roots in bounded time series.
{it:Journal of Econometrics} 178: 259-272.
{browse "https://doi.org/10.1016/j.jeconom.2013.08.026":doi:10.1016/j.jeconom.2013.08.026}.

{phang}
Harvey, D. I., S. J. Leybourne, and A. M. R. Taylor. 2010. Robust methods for detecting
multiple level breaks in autocorrelated time series. {it:Journal of Econometrics} 157: 342-358.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit root tests with
good size and power. {it:Econometrica} 69: 1519-1554.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
