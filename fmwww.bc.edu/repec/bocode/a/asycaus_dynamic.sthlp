{smcl}
{* *! version 1.0.4  19jul2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus static" "help asycaus_static"}{...}
{vieweralsosee "asycaus fourier" "help asycaus_fourier"}{...}
{vieweralsosee "tvgc" "help tvgc"}{...}

{title:Title}

{phang}{bf:asycaus dynamic} {hline 2} Hatemi-J (2021) dynamic asymmetric causality (rolling / recursive subsamples)

{title:Syntax}

{p 8 17 2}
{cmd:asycaus dynamic} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
Extends the static asymmetric test (Hatemi-J 2012) to a time-varying setting
by re-estimating the causal relationship over overlapping subsamples. Two
subsampling schemes are provided:{p_end}

{phang}{bf:rolling} — fixed-length window of size {it:S} moved one observation at a time.{p_end}
{phang}{bf:recursive} — anchored at the first observation, expanding by one each step.{p_end}

{pstd}
The minimum window {it:S} defaults to the Phillips, Shi & Yu (2015) lower bound:{p_end}
{p 12 12 2}{it:S = ceil[T(0.01 + 1.8/sqrt(T))]}{p_end}
{pstd}
For each window the leverage-adjusted bootstrap is run; 1%, 5%, 10% critical
values and the ratio {it:Wald / CV5} are reported. A time-varying-causality
graph is produced unless {opt nograph} is set.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 4){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} (default pos){p_end}
{synopt :{opt tr:end(string)}}component transform: {bf:none} (default) | {bf:drift} | {bf:both} (Hatemi-J and El-Khatib 2016){p_end}
{synopt :{opt wind:ow(#)}}rolling/recursive window length (default = PSY min){p_end}
{synopt :{opt rol:ling}}rolling window (default){p_end}
{synopt :{opt rec:ursive}}recursive (anchored) window{p_end}
{synopt :{opt boot(#)}}bootstrap reps per window (default 200){p_end}
{synopt :{opt seed(#)}}seed (default 12345){p_end}
{synopt :{opt ln:form}}use ln of inputs first{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opt sav:ing(name)}}save graph{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus dynamic dln_inv dln_inc, rolling window(40) boot(200) shock(pos)"}{p_end}
{phang}{stata "asycaus dynamic dln_inv dln_inc, recursive boot(200) shock(neg)"}{p_end}

{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt :{cmd:r(results)}}matrix: sub_start sub_end lag Wald cv10 cv5 cv1 W/cv5{p_end}
{synopt :{cmd:r(nsub)}}number of subsamples{p_end}
{synopt :{cmd:r(window)}}window length used{p_end}
{synopt :{cmd:r(Smin)}}PSY minimum window{p_end}
{synopt :{cmd:r(mode)} {cmd:r(shock)}}options used{p_end}

{title:References}

{phang}Hatemi-J, A. (2021). Dynamic Asymmetric Causality Tests with an Application. {it:arXiv} 2106.07612.{p_end}
{phang}Phillips, P. C. B., Shi, S., and Yu, J. (2015). Testing for multiple bubbles. {it:International Economic Review}, 56(4), 1043–1078.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
