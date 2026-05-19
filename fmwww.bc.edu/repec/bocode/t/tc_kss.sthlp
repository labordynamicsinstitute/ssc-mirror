{smcl}
{title:Title}
{p 4 4 2}{bf:tc_kss} {hline 2} KSS (2006) nonlinear cointegration test (ESTAR)

{title:Syntax}
{p 4 8 2}
{cmd:tc_kss} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt case(1|2|3)} {opt maxlag(#)} {opt criterion(aic|bic)}]

{title:Description}
{pstd}
Kapetanios-Shin-Snell-style nonlinear cointegration test based on a cubic
transformation of residuals. {opt case(1)} raw, {opt case(2)} demeaned,
{opt case(3)} detrended.  Critical values from KSS (2006) /
{bf:NonlinearTSA} package.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_eg} | {helpb tc_bbc}{p_end}
