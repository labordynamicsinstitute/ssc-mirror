{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 20 21 2}{...}
{p2col :{cmd:ralsbattery} {hline 2}}One-shot battery of every RALS unit-root test on a single series{p_end}
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
{cmd:ralsbattery} {it:varlist} {ifin} [{cmd:,}
{opt trend}
{opt maxl:ags(#)}
{opt ic(string)}
{opt fmax(#)}
{opt g:raph}]

{phang}{it:varlist} may contain one or more time series.{p_end}

{title:Description}

{pstd}
{cmd:ralsbattery} is the one-shot driver that runs {bf:everything in the rals
package} on the supplied series:

{phang}{bf:1.} For each variable in {it:varlist}, a unit-root mini-battery is
run -- {help ralsdiag:ralsdiag}, then {help ralsadf:RALS-ADF},
{help ralslm:RALS-LM}, {help ralsfadf:RALS-Fourier ADF},
{help ralsfkss:RALS-Fourier KSS} and {help ralslmb:RALS-LM with one endogenous
break} (model 2).{p_end}

{phang}{bf:2.} If {it:varlist} contains two or more series, a cointegration
battery is run on (dep = first variable, regressors = the rest): the four
single-equation tests of {help ralscoint:ralscoint} (ECM, ADL, EG, EG2) plus
{help ralsfadl:ralsfadl} (Fourier ADL).{p_end}

{pstd}
Each test prints one line in a unified table (stat, 5% CV at stage-1; stat,
5% CV, rho^2 at stage-2; verdict).  The end-of-run summary reports how many
tests reject the null at 5% across the whole package, and the optional
{opt graph} draws a forest plot of every RALS statistic against its critical
value, colour-coded by reject / no reject.

{title:Options}

{phang}{opt trend} include a linear trend in every test.  Without this only a
constant is fitted (where each test supports it).{p_end}

{phang}{opt maxlags(#)} maximum lag used by each test's lag-selection
procedure (default 8).{p_end}

{phang}{opt ic(string)} information criterion used to pick the lag:
{bf:aic} | {bf:bic} | {bf:tstat} (default).{p_end}

{phang}{opt fmax(#)} maximum Fourier frequency searched by the Fourier-augmented
tests (default 5).{p_end}

{phang}{opt graph} draws a forest plot of each RALS statistic with its 5%
critical value, color-coded by reject / no-reject.{p_end}

{phang}{opt saving(filename)} reserved for a future export of the result
matrix to a CSV/Excel file.{p_end}

{title:Examples}

{pstd}{it:Unit-root only -- one series:}{p_end}
{phang2}{cmd:. sysuse sp500, clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. ralsbattery close, trend graph}{p_end}

{pstd}{it:Multiple variables -- unit-root for each + cointegration battery:}{p_end}
{phang2}{cmd:. ralsbattery close volume open, trend graph}{p_end}

{title:Stored results}

{pstd}{cmd:ralsbattery} stores the following in {bf:r()}:

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(unitroot)}}stacked matrix: 5 rows per variable, columns =
stage-1 stat, stage-1 5% CV, RALS stat, RALS 5% CV, rho^2, stage-1 reject,
RALS reject, extra (k or break date){p_end}
{synopt:{cmd:r(coint)}}(if {it:varlist} has ≥ 2 vars) 5x5 matrix of cointegration
results (ECM/ADL/EG/EG2/Fourier-ADL){p_end}
{synopt:{cmd:r(n_rej_rals)}}total RALS rejections across all variables{p_end}
{synopt:{cmd:r(n_tests)}}total RALS unit-root tests run{p_end}
{synopt:{cmd:r(n_coint_rej)}}RALS cointegration rejections (if applicable){p_end}
{synopt:{cmd:r(T)}}sample size used{p_end}
{synopt:{cmd:r(variables)}}variable list{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Individual tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
