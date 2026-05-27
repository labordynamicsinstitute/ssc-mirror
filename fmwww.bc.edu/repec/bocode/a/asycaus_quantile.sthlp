{smcl}
{* *! version 1.0.2  24may2026}{...}
{vieweralsosee "[asycaus] main" "help asycaus"}{...}
{vieweralsosee "asycaus fourier" "help asycaus_fourier"}{...}
{vieweralsosee "qreg" "help qreg"}{...}

{title:Title}

{phang}{bf:asycaus quantile} {hline 2} Fang, Wang, Shieh & Chung (2026) quantile asymmetric causality (optional Fourier)

{title:Syntax}

{p 8 17 2}
{cmd:asycaus quantile} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{title:Description}

{pstd}
Combines the asymmetric causality framework ({bf:Hatemi-J 2012}) with
quantile-VAR estimation ({bf:Koenker 2005}), as in {bf:Fang, Wang, Shieh and
Chung (2026)}. For each requested quantile tau, a quantile regression is
fitted to the cumulative positive (or negative) components and a Wald test of
non-causality is computed using the asymptotic variance with sparsity
correction.{p_end}

{pstd}
Optionally the Fourier basis can be projected out first ({opt fourier}),
matching the Fang et al. specification where smooth structural breaks are
absorbed by trigonometric expansions before quantile causality is tested.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopt :{opt maxl:ag(#)}}max VAR lag (default 4){p_end}
{synopt :{opt ic(string)}}IC (default hjc){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (default 1){p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} | {bf:both}{p_end}
{synopt :{opt q:uantiles(numlist)}}quantiles in (0,1). Default 0.1 0.25 0.5 0.75 0.9{p_end}
{synopt :{opt fou:rier}}detrend components with Fourier basis first{p_end}
{synopt :{opt kmax(#)}}max Fourier frequency when {opt fourier} is set (default 3){p_end}
{synopt :{opt ln:form}}log of inputs{p_end}
{synopt :{opt nograph}}suppress graph{p_end}
{synopt :{opt sav:ing(name)}}save graph{p_end}

{title:Examples}

{phang}{stata "webuse lutkepohl2, clear"}{p_end}
{phang}{stata "tsset qtr"}{p_end}
{phang}{stata "asycaus quantile dln_inv dln_inc, quantiles(0.1 0.25 0.5 0.75 0.9)"}{p_end}
{phang}{stata "asycaus quantile dln_inv dln_inc, quantiles(0.1 0.25 0.5 0.75 0.9) fourier kmax(2)"}{p_end}

{title:Stored results}

{synoptset 22 tabbed}{...}
{synopt :{cmd:r(results)}}matrix: shock_id, tau, Wald, lag, asy_p, reject5{p_end}
{synopt :{cmd:r(shock)}}option used{p_end}

{title:References}

{phang}Fang, H., Wang, C.-H., Shieh, J. C. P., and Chung, C.-P. (2026). The asymmetric Granger causality between banking-sector and stock-market development and economic growth in quantiles considering Fourier. {it:Applied Economics}, 58(20), 3822–3838.{p_end}
{phang}Koenker, R. (2005). {it:Quantile Regression}. Cambridge University Press.{p_end}

{title:Author}
{pstd}{bf:Dr Merwan Roudane} {hline 2} {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}See {help asycaus:asycaus} for the package overview.{p_end}
