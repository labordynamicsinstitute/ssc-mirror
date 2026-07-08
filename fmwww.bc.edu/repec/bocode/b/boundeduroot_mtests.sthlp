{smcl}
{* *! version 1.0.0  07jul2026  Merwan Roudane}{...}
{vieweralsosee "boundeduroot" "help boundeduroot"}{...}
{vieweralsosee "boundeduroot breaks" "help boundeduroot_breaks"}{...}
{vieweralsosee "boundeduroot hlt" "help boundeduroot_hlt"}{...}
{vieweralsosee "boundedur" "help boundedur"}{...}
{viewerjumpto "Syntax" "boundeduroot_mtests##syntax"}{...}
{viewerjumpto "Description" "boundeduroot_mtests##description"}{...}
{viewerjumpto "Options" "boundeduroot_mtests##options"}{...}
{viewerjumpto "Stored results" "boundeduroot_mtests##results"}{...}
{viewerjumpto "Examples" "boundeduroot_mtests##examples"}{...}
{viewerjumpto "References" "boundeduroot_mtests##references"}{...}
{title:Title}

{phang}
{bf:boundeduroot mtests} {hline 2} GLS-based M unit-root tests for bounded series (CSG 2013)

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:boundeduroot mtests} {varname} {ifin}{cmd:,}
{cmdab:lb:ound(}{it:#}{cmd:)} {cmdab:ub:ound(}{it:#}{cmd:)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lb:ound(#)}}lower bound {it:b} (required; {cmd:.} = one-sided){p_end}
{synopt:{opt ub:ound(#)}}upper bound {it:b-bar} (required; {cmd:.} = one-sided){p_end}
{synopt:{opt i:ter(#)}}Monte Carlo draws for the simulated critical values; default {cmd:1000}{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag for MAIC / spectral AR LRV; default {cmd:floor(12*(T/100)^.25)}{p_end}
{synopt:{opt seed(#)}}RNG seed for the critical-value simulation; default {cmd:16384}{p_end}
{synopt:{opt l:evel(#)}}significance level of the reported critical value; default {cmd:c(level)}{p_end}
{synopt:{opt nograph}}suppress the diagnostic figure{p_end}
{synopt:{opt gname(string)}}name stub for the produced graphs{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:boundeduroot mtests} computes the modified {c 34}M{c 34} unit-root tests
(MSB, MZ{sub:{&alpha}}, MZ{sub:t}) of Perron-Ng / Ng-Perron (2001) for a {it:bounded}
series, under three detrending schemes crossed with two long-run variance (LRV) estimators,
giving six configurations reported together:

{p2colset 9 42 44 2}{...}
{p2col:{space 2}{bf:OLS} / SAR, OLS / QS}OLS de-meaning, parametric and non-parametric LRV{p_end}
{p2col:{space 2}{bf:GLS-ERS} / SAR, GLS-ERS / QS}pseudo-GLS de-meaning at c-bar = -7{p_end}
{p2col:{space 2}{bf:GLS-BOUNDS} / SAR, GLS-BOUNDS / QS}GLS de-meaning at a bound-dependent c-bar = kappa-hat{p_end}

{pstd}
The GLS-BOUNDS scheme estimates the pseudo-GLS noncentrality {cmd:kappa-hat} by interpolating
the Carrion-i-Silvestre & Gadea (2013) response surface over the standardised bounds
{cmd:(c, c-bar)}. Each of the six statistics is compared with its own critical values, obtained
by simulating a regulated (reflected) Brownian motion folded into {cmd:[c*sqrt(T), c-bar*sqrt(T)]}
and recomputing the same statistic on each draw. All three tests reject the bounded unit-root
null for {it:small} values of the statistic.

{marker options}{...}
{title:Options}

{phang}{opt lbound(#)} and {opt ubound(#)} give the (known) bounds; at least one must be finite.

{phang}{opt iter(#)} sets the number of Monte Carlo replications for the simulated critical
values (6 configurations are simulated). Larger values are more accurate but slower.

{phang}{opt maxlag(#)} caps the MAIC search for the spectral AR long-run variance.

{phang}{opt seed(#)} fixes the random-walk bank so results are reproducible; {opt level(#)}
selects which simulated quantile (1/2.5/5/10%) is shown as the critical value.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:boundeduroot mtests} stores in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(x0)}}first observation X0{p_end}
{synopt:{cmd:r(kappa_ar)} {cmd:r(kappa_np)}}estimated GLS-BOUNDS kappa (SAR / QS){p_end}
{synopt:{cmd:r(lbound)} {cmd:r(ubound)} {cmd:r(iter)}}bounds and #draws{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}6{c 215}3 statistics (rows = configs; cols MSB MZa MZt){p_end}
{synopt:{cmd:r(cv_msb)} {cmd:r(cv_mza)} {cmd:r(cv_mzt)}}6{c 215}4 CVs (1/2.5/5/10%){p_end}
{synopt:{cmd:r(cpars)}}6{c 215}2 standardised bounds (c, c-bar) per config{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. tsset time}{p_end}
{phang2}{cmd:. boundeduroot mtests urate, lbound(0) ubound(100)}{p_end}
{phang2}{cmd:. boundeduroot mtests irate, lbound(0) iter(5000) seed(99)}{p_end}

{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2013. GLS-based unit root tests for bounded
processes.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit root tests with
good size and power. {it:Econometrica} 69: 1519-1554.

{title:Author}

{pstd}
Dr Merwan Roudane -- merwanroudane920@gmail.com -- {browse "https://github.com/merwanroudane":github.com/merwanroudane}
