{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_johansen}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_johansen} {hline 2} Two-step Johansen I(2) VAR with Paruolo
joint Q(r, s_1) rank test

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_johansen} {it:varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lags(#)}}VAR(k); requires k >= 2{p_end}
{synopt :{opt tr:end(spec)}}{bf:none}, {bf:c} (default), {bf:ct}{p_end}
{synopt :{opt r:ank(#)}}choose cointegration rank r (default = auto){p_end}
{synopt :{opt s1(#)}}choose number of I(1) trends s_1 (default = auto){p_end}
{synopt :{opt jo:int}}run the full Paruolo Q(r, s_1) rank table{p_end}
{synopt :{opt alpha(#)}}significance level for auto rank pick{p_end}
{synoptline}

{title:Description}

{pstd}
Two reduced-rank steps following Johansen (1995, 1997):

{phang2}
Step 1 - standard I(1) trace analysis on {Pi} = {alpha}{beta}' to fix the
cointegration rank r.{p_end}

{phang2}
Step 2 - reduced-rank regression of {alpha}'{perp}{Delta}^2 X_t on
{beta}{perp}{Delta} X_{t-1} (controlling for lagged second differences
and {beta}'{Delta} X_{t-1}), to fix s_1 — the dimension of the I(1)
common stochastic trends.

{pstd}
The Paruolo joint statistic Q(r, s_1) = trace_1(r) + trace_2(s_1) is
asymptotically chi-squared and is the test recommended by Juselius
(2006), Kurita (2011) and Majsterek (2012) for I(2) rank determination.
The full Q table is printed when {opt joint} is specified.

{title:Stored results}

{phang}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:e(rank)}}selected r{p_end}
{synopt :{cmd:e(s1)}}selected s_1{p_end}
{synopt :{cmd:e(s2)}}p - r - s_1 = I(2) common trends{p_end}
{synopt :{cmd:e(p)}}number of variables{p_end}
{synopt :{cmd:e(N)}}sample size{p_end}
{synopt :{cmd:e(lags)}}VAR order{p_end}

{phang}Matrices{p_end}
{synopt :{cmd:e(beta)}}p x r cointegrating vectors (normalised){p_end}
{synopt :{cmd:e(alpha)}}p x r loadings{p_end}
{synopt :{cmd:e(beta_p)}}p x (p-r) orthogonal complement of beta{p_end}
{synopt :{cmd:e(alpha_p)}}p x (p-r) orthogonal complement of alpha{p_end}
{synopt :{cmd:e(beta1)}}p x s_1 directions of I(1) common trends{p_end}
{synopt :{cmd:e(beta2)}}p x s_2 directions of I(2) common trends{p_end}
{synopt :{cmd:e(Q)}}Paruolo Q(r, s_1) joint table{p_end}

{title:Examples}

{phang}{bf:1. Auto-pick (r, s_1) with the joint Q table}{p_end}
{p 8 16 2}{stata "mixi12_johansen m2 mb p rd, lags(3) trend(c) joint"}{p_end}

{phang}{bf:2. Force the rank you obtained from theory}{p_end}
{p 8 16 2}{stata "mixi12_johansen m2 mb p rd, lags(3) rank(1) s1(1)"}{p_end}

{phang}{bf:3. Test a money-multiplier transformation afterwards}{p_end}
{p 8 16 2}{stata "matrix G = (1 \ -1 \ 0 \ 0)"}{p_end}
{p 8 16 2}{stata "mixi12_trans, g(G)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_trans}, {helpb mixi12_sw}, {helpb mixi12_sim},
{helpb mixi12_graph}, {helpb mixi12_cv}.
