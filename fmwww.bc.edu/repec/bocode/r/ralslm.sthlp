{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col :{cmd:ralslm} {hline 2}}RALS-LM unit-root test of Meng, Im, Lee & Tieslau (2014){p_end}
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
{cmd:ralslm} {it:varname} {ifin} [{cmd:,} {opt maxl:ags(#)} {opt ic(string)} {opt g:raph} {opt nohea:der}]

{title:Description}

{pstd}
{cmd:ralslm} performs the two-stage RALS Lagrange-Multiplier unit-root test
of Meng, Im, Lee & Tieslau (2014).  The series is first detrended
Schmidt-Phillips style; the LM statistic is then computed on the detrended
residuals and corrected via the RALS w-augmentation built from the second
and third moments of the regression residuals.

{pstd}
The deterministic component is fixed at a linear trend (model 2 of the GAUSS
source rals_lm.src); for a constant-only model use {help ralsadf:ralsadf}.

{title:Options}

{phang}{opt maxlags(#)} maximum lag of Ds_t considered (default 8).{p_end}
{phang}{opt ic(string)} {bf:aic}, {bf:bic} or {bf:tstat} (default).{p_end}
{phang}{opt graph} draws a time-series plot with the RALS-LM statistic.{p_end}
{phang}{opt noheader} omits the header.{p_end}

{title:Examples}

{phang2}{cmd:. sysuse sp500, clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. ralslm close}{p_end}
{phang2}{cmd:. ralslm close, ic(bic) graph}{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(tauLM)}}stage-1 LM statistic{p_end}
{synopt:{cmd:r(tauRALS)}}RALS-LM statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(lag)}}lag length selected{p_end}
{synopt:{cmd:r(T)}}sample size used{p_end}
{synopt:{cmd:r(cv01_LM)}, {cmd:r(cv05_LM)}, {cmd:r(cv10_LM)}}stage-1 LM critical values{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}stage-2 RALS critical values{p_end}

{title:References}

{phang}Meng, M., Im, K.S., Lee, J., Tieslau, M.A. (2014). More powerful LM unit-root tests with non-normal errors. In {it:Festschrift in Honor of Peter Schmidt}, 343-357.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
