{smcl}
{* *! version 1.0.1  21may2026}{...}
{cmd:help mixi12_haldrup}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_haldrup} {hline 2} Haldrup (1994 JoE) single-equation
residual-based ADF cointegration test (delegates to {helpb dptest})

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_haldrup} {it:depvar} {ifin} {cmd:,} {opth i2(varlist)}
[{opth i1(varlist)} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth i2(varlist)}}I(2) regressors (at least one required){p_end}
{synopt :{opth i1(varlist)}}I(1) regressors (may be empty){p_end}
{synopt :{opt det(spec)}}{bf:none}, {bf:const} (default), {bf:trend}, {bf:qtrend}{p_end}
{synopt :{opt maxl:ag(#)}}ADF max lag (−1 = Schwert, default){p_end}
{synopt :{opt le:vel(#)}}1, 5 (default), 10{p_end}
{synopt :{opt crit(name)}}{bf:bic} (default) or {bf:aic}{p_end}
{synoptline}

{title:Description}

{pstd}
Tests the null of no cointegration between {it:depvar} and the supplied
I(1) and I(2) regressors using the residual-based ADF test of Haldrup
(1994 J. Econometrics 63: 153-181).  Critical values follow Haldrup's
Table 1 (intercept included) and are indexed by (m1, m2, T).

{pstd}
The actual regression, the ADF stage and the critical-value lookup are
performed by {helpb dptest} (Roudane 2026, sub-test {bf:coint}); this
wrapper just exposes the cointegration test inside the mixi12 visual
style with the {opt i1()} / {opt i2()} option names familiar to users
of {helpb mixi12_johansen} and {helpb mixi12_sw}.

{title:Stored results}

{phang}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:r(t)}}ADF t-statistic on the static residual{p_end}
{synopt :{cmd:r(cv01) / r(cv05) / r(cv10)}}Haldrup Table 1 critical values{p_end}
{synopt :{cmd:r(lags)}}ADF lag length used by dptest{p_end}
{synopt :{cmd:r(N)}}effective sample{p_end}
{synopt :{cmd:r(m1) / r(m2)}}numbers of I(1) / I(2) regressors{p_end}
{synopt :{cmd:r(reject)}}1 if H0 of no cointegration is rejected{p_end}
{synopt :{cmd:r(verdict)}}reject / do-not-reject sentence{p_end}

{title:Examples}

{phang}{bf:1.  Long-run money demand in nominal levels}{p_end}
{p 8 16 2}{stata "mixi12_haldrup m2, i1(rd) i2(mb p) det(trend)"}{p_end}

{phang}{bf:2.  Force a Schwert-bound lag and test at 1%}{p_end}
{p 8 16 2}{stata "mixi12_haldrup m2, i1(rd) i2(mb p) det(const) maxlag(8) level(1)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_johansen},
{helpb mixi12_trans}, {helpb mixi12_sw}, {helpb mixi12_sim},
{helpb mixi12_graph}, {helpb mixi12_cv}.
Engine: {helpb dptest}.
