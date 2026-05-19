{smcl}
{title:Title}
{p 4 4 2}{bf:tc_setar} {hline 2} SETAR(2) -- Self-Exciting Threshold Autoregressive model

{title:Syntax}
{p 4 8 2}
{cmd:tc_setar} {it:varname} {ifin} [{cmd:,} {opt lag(#)} {opt delay(#)} {opt threshold(#)} {opt trim(#)} {opt ngrid(#)}]

{title:Description}
{pstd}
Two-regime SETAR with switching governed by {it:y_{t-d}} where {it:d} is
specified through {opt delay()}.  If {opt threshold(#)} is omitted, the
optimal threshold is chosen by SSR minimisation over a trimmed grid.

{title:Stored results}
{pstd}{cmd:r(threshold)}, {cmd:r(lag)}, {cmd:r(nregime1)}, {cmd:r(nregime2)}, {cmd:r(ssr)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_tar} | {helpb tc_eqtar} | {helpb tc_bbc} | {helpb tc_tvecm}{p_end}
