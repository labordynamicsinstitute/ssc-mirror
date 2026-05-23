{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_sw}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_sw} {hline 2} Stock-Watson (1993) triangular estimator for
mixed I(1) / I(2) systems

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_sw} {it:depvar} {ifin} {cmd:,} {opth i1(varlist)}
{opth i2(varlist)} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth i1(varlist)}}I(1) regressors{p_end}
{synopt :{opth i2(varlist)}}I(2) regressors{p_end}
{synopt :{opt le:ads(#)}}leads of {Delta} I(1)/I(2) regressors (default 2){p_end}
{synopt :{opt lagsd:iff(#)}}lags of same (default 2){p_end}
{synopt :{opt tr:end(spec)}}{bf:c} (default), {bf:ct}{p_end}
{synopt :{opt hac}}use Newey-West HAC standard errors{p_end}
{synopt :{opt bw(#)}}HAC bandwidth (0 = Newey-West rule){p_end}
{synopt :{opt level(#)}}confidence level (default 95){p_end}
{synoptline}

{title:Description}

{pstd}
Implements the leads-and-lags estimator of Stock & Watson (1993) for
single-equation cointegrating regressions that mix I(1) and I(2)
regressors.  The augmentation by leads and lags of all first differences
removes long-run endogeneity so the estimated long-run coefficients have
a mixed-Gaussian limiting distribution; the printed t-ratios and p-values
are then asymptotically valid.

{pstd}
For small samples, request the {opt hac} option to use Newey-West HAC
standard errors instead of the default OLS-based variance.

{title:Examples}

{phang}{bf:Standard SW with two leads and two lags}{p_end}
{p 8 16 2}{stata "mixi12_sw m2 , i1(rd) i2(mb p) leads(2) lagsdiff(2)"}{p_end}

{phang}{bf:HAC inference, broken linear trend}{p_end}
{p 8 16 2}{stata "mixi12_sw m2 , i1(rd) i2(mb p) leads(3) lagsdiff(3) trend(ct) hac"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sim},
{helpb mixi12_graph}, {helpb mixi12_cv}.
