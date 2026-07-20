{smcl}
{* *! version 1.0.4  19jul2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus static" "help asycaus_static"}{...}
{vieweralsosee "asycaus dynamic" "help asycaus_dynamic"}{...}
{vieweralsosee "asycaus fourier" "help asycaus_fourier"}{...}
{vieweralsosee "asycaus spectral" "help asycaus_spectral"}{...}
{vieweralsosee "asycaus quantile" "help asycaus_quantile"}{...}
{vieweralsosee "asycaus efficient" "help asycaus_efficient"}{...}

{title:Title}

{phang}{bf:asycaus all} {hline 2} Comprehensive asymmetric causality battery with unified summary and dashboard

{title:Syntax}

{p 8 17 2}
{cmd:asycaus all} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
Runs the full battery of asymmetric Granger-causality tests on a single pair
of variables and prints a {bf:unified summary table} at the end (one row per
test x shock type). A combined dashboard graph is produced unless {opt nograph}
is set.{p_end}

{pstd}Tests included (skipped tests can be turned off with the {bf:skip*} flags):{p_end}

{phang}1. Static  {hline 2} Hatemi-J (2012){p_end}
{phang}2. Fourier {hline 2} Nazlioglu, Gormus & Soytas (2016){p_end}
{phang}3. Efficient {hline 2} Hatemi-J (2024){p_end}
{phang}4. Spectral {hline 2} Bahmani-Oskooee, Chang & Ranjbar (2016){p_end}
{phang}5. Quantile {hline 2} Fang, Wang, Shieh & Chung (2026){p_end}
{phang}*. Dynamic {hline 2} Hatemi-J (2021) — runs by default; turn off with {opt skipdynamic}{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 4){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt boot(#)}}bootstrap reps (default 500){p_end}
{synopt :{opt seed(#)}}seed (default 12345){p_end}
{synopt :{opt kmax(#)}}max Fourier frequency (default 5){p_end}
{synopt :{opt nfreq(#)}}number of spectral frequencies (default 50){p_end}
{synopt :{opt q:uantiles(numlist)}}quantiles for the quantile test{p_end}
{synopt :{opt wind:ow(#)}}rolling window for the dynamic test{p_end}
{synopt :{opt ln:form}}log of inputs{p_end}
{synopt :{opt skipdynamic}}skip the dynamic time-varying test (faster){p_end}
{synopt :{opt skipspectral}}skip the spectral test{p_end}
{synopt :{opt skipquantile}}skip the quantile test{p_end}
{synopt :{opt nograph}}suppress graphs{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus all dln_inv dln_inc, maxlag(4) boot(300)"}{p_end}
{phang}{stata "asycaus all dln_inv dln_inc, maxlag(4) boot(300) skipdynamic skipspectral"}{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
