{smcl}
{title:Title}

{p 4 4 2}{bf:tc_pp} {hline 2} Phillips-Perron unit-root test

{title:Syntax}

{p 4 8 2}
{cmd:tc_pp} {it:varname} {ifin} [{cmd:,} {opt lags(#)} {opt case(nc|c|ct)}]

{title:Description}
{pstd}
Phillips-Perron Z(t) test using Newey-West long-run variance.  Bandwidth
defaults to ⌊4·(T/100)^(2/9)⌋.

{title:Stored results}
{pstd}{cmd:r(stat)}  {cmd:r(lags)}  {cmd:r(nobs)}  {cmd:r(cv)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adf} | {helpb tc_eg}{p_end}
