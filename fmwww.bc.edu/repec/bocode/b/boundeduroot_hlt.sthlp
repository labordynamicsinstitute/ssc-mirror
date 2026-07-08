{smcl}
{* *! version 1.0.0  07jul2026  Merwan Roudane}{...}
{vieweralsosee "boundeduroot" "help boundeduroot"}{...}
{vieweralsosee "boundeduroot mtests" "help boundeduroot_mtests"}{...}
{vieweralsosee "boundeduroot breaks" "help boundeduroot_breaks"}{...}
{vieweralsosee "boundedur" "help boundedur"}{...}
{viewerjumpto "Syntax" "boundeduroot_hlt##syntax"}{...}
{viewerjumpto "Description" "boundeduroot_hlt##description"}{...}
{viewerjumpto "Options" "boundeduroot_hlt##options"}{...}
{viewerjumpto "Stored results" "boundeduroot_hlt##results"}{...}
{viewerjumpto "Examples" "boundeduroot_hlt##examples"}{...}
{viewerjumpto "References" "boundeduroot_hlt##references"}{...}
{title:Title}

{phang}
{bf:boundeduroot hlt} {hline 2} Bounded multiple level-shift detection, HLT (CSG 2024)

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:boundeduroot hlt} {varname} {ifin}{cmd:,}
{cmdab:lb:ound(}{it:#}{cmd:)} {cmdab:ub:ound(}{it:#}{cmd:)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lb:ound(#)}}lower bound {it:b} (required){p_end}
{synopt:{opt ub:ound(#)}}upper bound {it:b-bar} (required){p_end}
{synopt:{opt w:indow(#)}}window fraction m; one of 0.10, 0.15 (default), 0.20, 0.25, 0.30{p_end}
{synopt:{opt i:ter(#)}}Monte Carlo draws per candidate break; default {cmd:400}{p_end}
{synopt:{opt seed(#)}}RNG seed; default {cmd:1}{p_end}
{synopt:{opt l:evel(#)}}confidence level; maps to CV percentile 90/95/97.5/99; default {cmd:c(level)}{p_end}
{synopt:{opt nograph}}suppress the diagnostic figure{p_end}
{synopt:{opt gname(string)}}name stub for the produced graph{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:boundeduroot hlt} detects multiple level shifts in a {it:bounded} time series, whatever its
order of integration, following Carrion-i-Silvestre & Gadea (2024), Case A (the boundaries do
not change). It first locates candidate break dates from the moving forward-minus-backward mean
{cmd:M(t)}, then forms the Harvey-Leybourne-Taylor (2010) statistics

{p 10 10 2}{cmd:S1 = max|M| / sqrt(T) / sqrt(omega_e)}{space 4}(uses the I(1) long-run variance),{p_end}
{p 10 10 2}{cmd:S0 = max|M| * sqrt(T) / sqrt(omega_u)}{space 4}(uses the I(0) long-run variance),{p_end}

{pstd}
where {cmd:omega_e} and {cmd:omega_u} are autoregressive long-run variances of the differenced
and level residuals. Because the series is bounded, the critical values are {it:not} the original
HLT constants; instead the command simulates, for each candidate break, a regulated (reflected)
Brownian motion (for S1, from a bounded I(1) path) and a bounded I(0) process (for S0), with the
bounds shifted by the cumulative mean of the earlier breaks, and reports the bound-specific
critical values together with a union (U) decision. A break is flagged as a genuine level shift
when its statistic exceeds the simulated critical value.

{pstd}
{it:Note.} The command is simulation-intensive (each candidate break requires {cmd:iter} bounded
paths, each re-running the detection and two long-run-variance estimators); expect a wait of tens
of seconds. Start with the default {cmd:iter(400)} and raise it for final results.

{marker options}{...}
{title:Options}

{phang}{opt lbound(#)}, {opt ubound(#)} give the (known, constant) bounds.

{phang}{opt window(#)} is the HLT window fraction m; it also fixes the maximum number of candidate
breaks (8, 5, 4, 3, 3 for m = 0.10, 0.15, 0.20, 0.25, 0.30).

{phang}{opt iter(#)}, {opt seed(#)}, {opt level(#)} control the simulated critical values and the
reported percentile.

{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(nbreaks)}}number of candidate breaks examined{p_end}
{synopt:{cmd:r(n_shift_s1)} {cmd:r(n_shift_s0)}}breaks flagged by S1 / S0{p_end}
{synopt:{cmd:r(omega_u)} {cmd:r(omega_e)}}level / difference long-run variances{p_end}
{synopt:{cmd:r(x0)} {cmd:r(lbound)} {cmd:r(ubound)}}first obs and bounds{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(result)}}nb{c 215}7: position, S1, S0, CV(S1), CV(S0), reject_S1, reject_S0{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. tsset time}{p_end}
{phang2}{cmd:. boundeduroot hlt urate, lbound(2) ubound(20)}{p_end}
{phang2}{cmd:. boundeduroot hlt urate, lbound(2) ubound(20) window(0.20) iter(1000)}{p_end}

{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2024. Detecting multiple level shifts in bounded
time series.

{phang}
Harvey, D. I., S. J. Leybourne, and A. M. R. Taylor. 2010. Robust methods for detecting multiple
level breaks in autocorrelated time series. {it:Journal of Econometrics} 157: 342-358.

{title:Author}

{pstd}
Dr Merwan Roudane -- merwanroudane920@gmail.com -- {browse "https://github.com/merwanroudane":github.com/merwanroudane}
