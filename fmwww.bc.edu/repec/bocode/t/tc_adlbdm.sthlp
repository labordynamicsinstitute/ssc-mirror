{smcl}
{title:Title}
{p 4 4 2}{bf:tc_adlbdm} {hline 2} ADL-BDM threshold cointegration test (Li & Lee 2010)

{title:Syntax}
{p 4 8 2}
{cmd:tc_adlbdm} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt maxlag(#)} {opt trim(#)} {opt ngrid(#)} {opt case(c|ct)}]

{title:Description}
{pstd}
ADL-based threshold cointegration test that does {it:not} require the
cointegrating vector to be pre-specified.  Statistic is the sup-|t| on the
lagged regressand across a grid of threshold values (BDM-style).  Bundles
finite-sample CVs for m = 1-4 regressors.

{title:Stored results}
{pstd}{cmd:r(sup_t)}, {cmd:r(threshold)}, {cmd:r(cv)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adlbo} | {helpb tc_sysadl} | {helpb tc_es}{p_end}
