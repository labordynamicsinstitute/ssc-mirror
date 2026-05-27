{smcl}
{* *! version 1.0.2  24may2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus static" "help asycaus_static"}{...}
{vieweralsosee "asycaus quantile" "help asycaus_quantile"}{...}

{title:Title}

{phang}{bf:asycaus fourier} {hline 2} Fourier-augmented asymmetric Toda-Yamamoto causality (Nazlioglu, Gormus & Soytas 2016; Pata 2020)

{title:Syntax}

{p 8 17 2}
{cmd:asycaus fourier} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
Augments the asymmetric Toda-Yamamoto VAR with Fourier trigonometric terms
{it:sin(2*pi*k*t/T)} and {it:cos(2*pi*k*t/T)} to control for {bf:smooth
structural breaks} of unknown number, timing and form ({bf:Enders and Lee 2012};
{bf:Nazlioglu, Gormus and Soytas 2016}). The asymmetric variant (Pata 2020)
applies the test to cumulative positive and negative shocks separately.{p_end}

{pstd}
Both {bf:single-frequency} and {bf:cumulative} Fourier bases are supported.
The optimal frequency {it:k}* in [1, {opt kmax}] is chosen automatically.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 8){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} | {bf:both}{p_end}
{synopt :{opt kmax(#)}}max Fourier frequency (default 5){p_end}
{synopt :{opt form(string)}}{bf:single} (default) or {bf:cumulative}{p_end}
{synopt :{opt boot(#)}}bootstrap reps (default 1000){p_end}
{synopt :{opt seed(#)}}seed (default 12345){p_end}
{synopt :{opt ln:form}}log of inputs{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opt sav:ing(name)}}save graph{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus fourier dln_inv dln_inc, kmax(3) form(single) shock(both)"}{p_end}
{phang}{stata "asycaus fourier dln_inv dln_inc, kmax(5) form(cumulative) shock(both)"}{p_end}

{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt :{cmd:r(results)}}matrix: Wald, lag, k*, asy_p, sample{p_end}
{synopt :{cmd:r(kmax)}}max Fourier frequency searched{p_end}
{synopt :{cmd:r(form)}}{bf:single} or {bf:cumulative}{p_end}

{title:References}

{phang}Enders, W., and Lee, J. (2012). The flexible Fourier form and Dickey-Fuller type unit root tests. {it:Economics Letters}, 117(1), 196–199.{p_end}
{phang}Nazlioglu, S., Gormus, N. A., and Soytas, U. (2016). Oil prices and real estate investment trusts (REITs): gradual-shift causality and volatility transmission analysis. {it:Energy Economics}, 60, 168–175.{p_end}
{phang}Pata, U. K. (2020). How is COVID-19 affecting environmental pollution in US cities? Evidence from asymmetric Fourier causality test. {it:Air Quality, Atmosphere & Health}, 13, 1149–1155.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
