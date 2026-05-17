{smcl}
{* *! version 1.0.1  16may2026}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col :{cmd:ralslmb} {hline 2}}RALS-LM unit-root test with 1 or 2 structural breaks (Meng, Lee & Payne 2017){p_end}
{p2colreset}{...}

{title:Navigation}

{p 4 4 2}
{help rals:Overview} {c |}
{help ralsadf:adf} {c |}
{help ralslm:lm} {c |}
{help ralslmb:lm-breaks} {c |}
{help ralsfadf:f-adf} {c |}
{help ralsfkss:f-kss} {c |}
{help ralsbattery:battery} {c |}
{help ralscoint:coint} {c |}
{help ralsfadl:f-adl} {c |}
{help ralsdiag:diag}
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:ralslmb} {it:varname} {ifin} [{cmd:,}
{opt mod:el(#)}
{opt br:eaks(#)}
{opt maxl:ags(#)}
{opt ic(string)}
{opt tr:imm(#)}
{opt g:raph}
{opt nohea:der}]

{title:Description}

{pstd}
{cmd:ralslmb} extends {help ralslm:ralslm} to allow up to two endogenously
located structural breaks.  Following the GAUSS code rals_lm_breaks.src the
optimal break date(s) are found by a grid search that minimises the LM
statistic.  The RALS w-augmentation is then evaluated at the chosen breaks
and lag length.  Critical values are from Meng, Lee & Tieslau (2014) for
model 1 and Meng, Lee & Payne (2017) for model 2, interpolated across rho^2.

{title:Options}

{phang}{opt model(#)} 1 = level break(s) only (Meng-Im-Lee-Tieslau 2014).
2 = level + trend break(s) (Meng-Lee-Payne 2017).  Default {bf:2}.{p_end}
{phang}{opt breaks(#)} 1 or 2.  Default {bf:1}.{p_end}
{phang}{opt maxlags(#)} maximum number of Ds_{t-i} lags (default 8).{p_end}
{phang}{opt ic(string)} {bf:aic}, {bf:bic} or {bf:tstat} (default).{p_end}
{phang}{opt trimm(#)} trimming for the break search; 0.10 follows ZA/LS.{p_end}
{phang}{opt graph} plots the series with the estimated break date(s) marked.{p_end}
{phang}{opt noheader} omits the header.{p_end}

{title:Examples}

{phang2}{cmd:. ralslmb gdp, model(2) breaks(2) graph}{p_end}
{phang2}{cmd:. ralslmb forest_footprint, model(1) breaks(1) maxlags(6) ic(bic)}{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(LMmin)}}minimised LM statistic{p_end}
{synopt:{cmd:r(tauRALS)}}RALS-LM statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(lag)}}lag length selected{p_end}
{synopt:{cmd:r(tb1)}, {cmd:r(tb2)}}break dates (time-series indices){p_end}
{synopt:{cmd:r(cv01_LM)}, {cmd:r(cv05_LM)}, {cmd:r(cv10_LM)}}stage-1 critical values{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}stage-2 RALS critical values{p_end}

{title:References}

{phang}Meng, M., Lee, J., Payne, J.E. (2017). RALS-LM unit-root test with trend breaks and non-normal errors: application to the Prebisch-Singer hypothesis.  {it:Studies in Nonlinear Dynamics & Econometrics} 21(1): 31-45.{p_end}

{phang}Nazlioglu, S., Lee, J. (2020). Response surface estimates of the LM unit-root tests. {it:Economics Letters} 192: 109136.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
