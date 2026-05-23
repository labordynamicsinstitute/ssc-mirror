{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_trans}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_trans} {hline 2} Kongsted (2005) / Kurita (2011) I(2)-to-I(1)
transformation LR test

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_trans} {cmd:,} {opt g(matname)} [{opt level(#)}]

{title:Description}

{pstd}
After {helpb mixi12_johansen} has produced an I(2) decomposition
({beta}, {beta}_{perp 1}, {beta}_{perp 2}), this command tests the null
sp(tau) = sp(G), where tau = ({beta}, {beta}_{perp 1}).  If the null is
not rejected, the linear combinations represented by the columns of G
constitute a valid transformation that reduces the I(2) data to I(1).

{pstd}
The test statistic is asymptotically chi-squared (Johansen 2006).  Typical
choices for G:

{phang2}
- Money multiplier on (m2, mb, p, rd): G = (1, -1, 0, 0)'.{p_end}
{phang2}
- Long-run price homogeneity on (m, p, y, R): G = (1, -1, 0, 0)'.{p_end}
{phang2}
- Nominal-to-real on (m, p, y): G = (1, -1, 0)'.{p_end}

{title:Stored results}

{phang}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:r(LR)}}LR statistic{p_end}
{synopt :{cmd:r(df)}}degrees of freedom{p_end}
{synopt :{cmd:r(p)}}chi-squared p-value{p_end}
{synopt :{cmd:r(verdict)}}reject / do not reject sentence{p_end}

{title:Examples}

{phang}{bf:1. Test the money multiplier on (m2, mb, p, rd)}{p_end}
{p 8 16 2}{stata "mixi12_johansen m2 mb p rd, lags(3) rank(1) s1(1)"}{p_end}
{p 8 16 2}{stata "matrix G = (1 \ -1 \ 0 \ 0)"}{p_end}
{p 8 16 2}{stata "mixi12_trans, g(G)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_sw}, {helpb mixi12_sim},
{helpb mixi12_graph}, {helpb mixi12_cv}.
