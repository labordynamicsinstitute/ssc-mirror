{smcl}
{* *! version 1.0.0  07jul2026  Merwan Roudane}{...}
{vieweralsosee "boundeduroot" "help boundeduroot"}{...}
{vieweralsosee "boundeduroot mtests" "help boundeduroot_mtests"}{...}
{vieweralsosee "boundeduroot hlt" "help boundeduroot_hlt"}{...}
{vieweralsosee "boundedur" "help boundedur"}{...}
{viewerjumpto "Syntax" "boundeduroot_breaks##syntax"}{...}
{viewerjumpto "Description" "boundeduroot_breaks##description"}{...}
{viewerjumpto "Options" "boundeduroot_breaks##options"}{...}
{viewerjumpto "Stored results" "boundeduroot_breaks##results"}{...}
{viewerjumpto "Examples" "boundeduroot_breaks##examples"}{...}
{viewerjumpto "References" "boundeduroot_breaks##references"}{...}
{title:Title}

{phang}
{bf:boundeduroot breaks} {hline 2} Bounded unit-root tests with structural breaks (CSG 2016)

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:boundeduroot breaks} {varname} {ifin}{cmd:,}
{cmdab:lb:ound(}{it:#}{cmd:)} {cmdab:ub:ound(}{it:#}{cmd:)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lb:ound(#)}}lower bound {it:b} (required){p_end}
{synopt:{opt ub:ound(#)}}upper bound {it:b-bar} (required){p_end}
{synopt:{opt br:eaks(spec)}}which configuration(s) to report: {opt 0}, {opt 1}, {opt 2} or {opt all} (default){p_end}
{synopt:{opt meth:od(type)}}long-run variance: {opt np} (non-parametric QS, default) or {opt ar} (parametric SAR){p_end}
{synopt:{opt i:ter(#)}}Monte Carlo draws for the simulated critical values; default {cmd:1000}{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag; default {cmd:round(4*(T/100)^.25)}{p_end}
{synopt:{opt seed(#)}}RNG seed; default {cmd:16384}{p_end}
{synopt:{opt l:evel(#)}}significance level of the reported critical value; default {cmd:c(level)}{p_end}
{synopt:{opt nograph}}suppress the diagnostic figure{p_end}
{synopt:{opt gname(string)}}name stub for the produced graph{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:boundeduroot breaks} tests the bounded unit-root null while allowing 0, 1 or 2 breaks in
the mean, following Carrion-i-Silvestre & Gadea (2016). Break dates are estimated by minimising
the sum of squared residuals of the {it:first-differenced} model (equivalently, by locating the
largest mean shifts), and the number of breaks is suggested by an SBIC over that model. For each
configuration the command reports five statistics {hline 1} MSB, MZ{sub:{&alpha}}, MZ{sub:t},
the variance ratio (VR) and the ADF-MAIC statistic {hline 1} together with critical values
simulated from a {it:piecewise} regulated Brownian motion in which each segment between breaks
is folded into its own bounds (the segment mean shifts by the estimated jumps, so the standardised
bounds shift with it). All five statistics reject the null in the left tail.

{marker options}{...}
{title:Options}

{phang}{opt lbound(#)}, {opt ubound(#)} give the (known, constant) bounds.

{phang}{opt breaks(spec)} restricts the printed rows to a given number of breaks; {opt all}
(default) prints the no-break, one-break and two-break rows.

{phang}{opt method(type)} chooses the long-run variance estimator; the paper's baseline is the
non-parametric QS estimator.

{phang}{opt iter(#)}, {opt maxlag(#)}, {opt seed(#)}, {opt level(#)} control the simulation and
reporting exactly as in {helpb boundeduroot_mtests:mtests}.

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(nbreaks)}}SBIC-recommended number of breaks{p_end}
{synopt:{cmd:r(tb1)}}estimated single-break position{p_end}
{synopt:{cmd:r(tb2_1)} {cmd:r(tb2_2)}}estimated two-break positions{p_end}
{synopt:{cmd:r(x0)} {cmd:r(lbound)} {cmd:r(ubound)}}first obs and bounds{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}3{c 215}5 statistics (rows 0/1/2 breaks; cols MSB MZa MZt VR ADF){p_end}
{synopt:{cmd:r(cv5)}}3{c 215}5 bound-specific critical values{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. tsset time}{p_end}
{phang2}{cmd:. boundeduroot breaks urate, lbound(0) ubound(100)}{p_end}
{phang2}{cmd:. boundeduroot breaks urate, lbound(0) ubound(100) breaks(1) method(ar)}{p_end}

{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2016. Bounds, breaks and unit root tests.
{it:Journal of Time Series Analysis} 37(2): 165-181.
{browse "https://doi.org/10.1111/jtsa.12144":doi:10.1111/jtsa.12144}.

{title:Author}

{pstd}
Dr Merwan Roudane -- merwanroudane920@gmail.com -- {browse "https://github.com/merwanroudane":github.com/merwanroudane}
