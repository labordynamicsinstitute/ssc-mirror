{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_cv}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_cv} {hline 2} Critical-value lookup for mixi12 tests

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_cv} {bf:haldrup} {cmd:,} {opt m1(#)} {opt m2(#)} {opt tsize(#)}

{p 8 14 2}
{cmd:mixi12_cv} {bf:johansen} {cmd:,} {opt df(#)}

{p 8 14 2}
{cmd:mixi12_cv} {bf:dp}

{title:Description}

{phang2}
{bf:haldrup} - Haldrup (1994b) Table 1 critical values for the
residual-based ADF I(2) cointegration test (intercept included).
Returns 1%, 2.5%, 5%, 10% critical values for the supplied (m1, m2,
T).{p_end}

{phang2}
{bf:johansen} - chi-squared(df) thresholds at 1%, 5%, 10% used by the
Paruolo Q(r, s_1) test.{p_end}

{phang2}
{bf:dp} - Pantula (1986) F-test critical values used by the
Dickey-Pantula sequential strategy in {helpb mixi12_unit}.{p_end}

{title:Examples}

{phang}{bf:1. Haldrup critical values for 2 I(1), 1 I(2), T = 150}{p_end}
{p 8 16 2}{stata "mixi12_cv haldrup, m1(2) m2(1) tsize(150)"}{p_end}

{phang}{bf:2. χ²(4) critical values}{p_end}
{p 8 16 2}{stata "mixi12_cv johansen, df(4)"}{p_end}

{phang}{bf:3. Pantula F table}{p_end}
{p 8 16 2}{stata "mixi12_cv dp"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sw},
{helpb mixi12_sim}, {helpb mixi12_graph}.
