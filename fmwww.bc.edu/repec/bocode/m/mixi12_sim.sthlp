{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12_sim}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12_sim} {hline 2} Simulate I(1), I(2) and Kurita-style monetary
data-generating processes

{title:Syntax}

{p 8 14 2}
{cmd:mixi12_sim} {cmd:,} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt dgp(name)}}{bf:i1}, {bf:i2}, {bf:km} (Kurita money multiplier){p_end}
{synopt :{opt n(#)}}sample length (default 200){p_end}
{synopt :{opt p(#)}}dimension for {bf:i1}/{bf:i2} DGPs (default 6){p_end}
{synopt :{opt rho1(#)}}near-I(2) coefficient (default 0){p_end}
{synopt :{opt omega(#)}}equilibrium-error coefficient in I(2) DGP (default 0){p_end}
{synopt :{opt seed(#)}}random seed{p_end}
{synopt :{opt clear}}allow overwriting data in memory{p_end}
{synoptline}

{title:Description}

{phang2}
- {bf:dgp(i1)} - Formula I(1) DGP of Doornik-Mosconi-Paruolo (2017):
half the variables are random walks (with optional AR(2) persistence via
rho1), the other half are stationary AR(1).{p_end}

{phang2}
- {bf:dgp(i2)} - Formula I(2) DGP: three blocks of variables, where the
first block is a pure cumulated random walk (I(2)), the second is a near
random walk (I(1) or near-I(2) when rho1=0.9) and the third is the
polynomial-cointegrated block governed by omega.{p_end}

{phang2}
- {bf:dgp(km)} - Kurita / monetary multiplier DGP: m2, mb share an I(2)
trend; p has its own I(2) trend; rd is I(1).  Use this DGP to exercise
{helpb mixi12_johansen} and {helpb mixi12_trans} in a known-truth
setting.{p_end}

{title:Examples}

{phang}{bf:1. Doornik-Mosconi-Paruolo I(2) circuit}{p_end}
{p 8 16 2}{stata "mixi12_sim, dgp(i2) n(500) p(6) rho1(0.9) omega(0.5) seed(11) clear"}{p_end}

{phang}{bf:2. Kurita monetary DGP}{p_end}
{p 8 16 2}{stata "mixi12_sim, dgp(km) n(160) seed(42) clear"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.

{title:Package}

{psee}Master: {helpb mixi12}.
Companions: {helpb mixi12_unit}, {helpb mixi12_haldrup},
{helpb mixi12_johansen}, {helpb mixi12_trans}, {helpb mixi12_sw},
{helpb mixi12_graph}, {helpb mixi12_cv}.
