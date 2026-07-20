{smcl}
{* *! version 1.0.4  19jul2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus static" "help asycaus_static"}{...}
{vieweralsosee "bcgcausality" "help bcgcausality"}{...}

{title:Title}

{phang}{bf:asycaus spectral} {hline 2} Bahmani-Oskooee, Chang & Ranjbar (2016) asymmetric frequency-domain causality

{title:Syntax}

{p 8 17 2}
{cmd:asycaus spectral} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
Implements the {bf:Breitung and Candelon (2006)} spectral causality test applied
separately to the cumulative {bf:positive} and {bf:negative} shocks of the two
variables ({bf:Bahmani-Oskooee, Chang and Ranjbar 2016}). At each frequency
w in (0, pi], the null{p_end}

{p 12 12 2}H0: M{sub:Y→X}(w) = 0{p_end}

{pstd}
is tested via a Wald statistic distributed as chi-square(2) under the asymptotic
distribution. The output reports the number of frequencies that reject H0 at
1%, 5%, and 10% for each shock type. The graph plots the Wald curve against
chi-square(2) critical values across the frequency grid — the classical
Bahmani-Oskooee et al. presentation.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 8){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} | {bf:both}{p_end}
{synopt :{opt nfreq(#)}}grid size in (0, pi] (default 50){p_end}
{synopt :{opt boot(#)}}bootstrap reps (reserved; default 500){p_end}
{synopt :{opt ln:form}}log of inputs{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opt sav:ing(name)}}save graph{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus spectral dln_inv dln_inc, nfreq(50) shock(both)"}{p_end}

{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt :{cmd:r(results)}}matrix: shock_id, omega, Wald, cv10, cv5, cv1 (per frequency){p_end}
{synopt :{cmd:r(nfreq)}}grid size{p_end}

{title:References}

{phang}Bahmani-Oskooee, M., Chang, T., and Ranjbar, O. (2016). Asymmetric causality using frequency-domain and time-frequency-domain (wavelet) approaches. {it:Economic Modelling}, 56, 66–78.{p_end}
{phang}Breitung, J., and Candelon, B. (2006). Testing for short- and long-run causality: a frequency-domain approach. {it:Journal of Econometrics}, 132, 363–378.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
