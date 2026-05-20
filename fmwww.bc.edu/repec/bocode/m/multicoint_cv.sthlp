{smcl}
{* *! version 1.0.0  18may2026}{...}
{cmd:help multicoint_cv}{right: (part of {bf:multicoint})}
{hline}

{title:Title}

{phang}
{bf:multicoint_cv} {hline 2} Critical values for the Engsted-Gonzalo-Haldrup
(1997) ADF test of multicointegration

{title:Package}

{p 4 6 2}
This command is part of the {helpb multicoint} library
({help multicoint##syntax:main}, {helpb multicoint_sim},
{helpb multicoint_graph}).

{title:Syntax}

{p 8 14 2}
{cmd:multicoint_cv} {cmd:,} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tr:end(spec)}}{bf:ct} (linear, default) or {bf:ctt} (quadratic){p_end}
{synopt :{opt m1(#)}}number of I(1) regressors (0..4){p_end}
{synopt :{opt m2(#)}}number of I(2) regressors (1 or 2){p_end}
{synopt :{opt ts:ize(#)}}sample size for interpolated value; abbreviates to {bf:t()}{p_end}
{synoptline}

{title:Description}

{pstd}
Displays the asymptotic critical values from Engsted, Gonzalo & Haldrup
(1997), Tables 1 and 2, for the augmented Dickey-Fuller t-statistic
applied to the residuals of the multicointegration regression with
m_1 I(1) regressors, m_2 I(2) regressors, and a linear ({bf:ct}) or
quadratic ({bf:ctt}) deterministic trend.  When {opt tsize(#)} is supplied,
the table values are linearly interpolated at the requested T and returned
in r().

{title:Examples}

{phang}{bf:1.  Full c.v. table, linear trend, m1=1, m2=1}{p_end}
{p 8 16 2}{stata "multicoint_cv, trend(ct) m1(1) m2(1)"}{p_end}

{phang}{bf:2.  Interpolated c.v. at T=350 with quadratic trend, m1=2, m2=1}{p_end}
{p 8 16 2}{stata "multicoint_cv, trend(ctt) m1(2) m2(1) tsize(350)"}{p_end}

{title:Stored results}

{phang}When {opt tsize(#)} is supplied:{p_end}
{synopt :{cmd:r(cv01)}}1% critical value{p_end}
{synopt :{cmd:r(cv025)}}2.5% critical value{p_end}
{synopt :{cmd:r(cv05)}}5% critical value{p_end}
{synopt :{cmd:r(cv10)}}10% critical value{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.{p_end}

{title:Also see}

{psee}Online:  {helpb multicoint}, {helpb multicoint_sim}, {helpb multicoint_graph}{p_end}
