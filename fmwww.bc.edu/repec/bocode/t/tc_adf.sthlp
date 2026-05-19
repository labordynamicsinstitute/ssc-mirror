{smcl}
{title:Title}

{p 4 4 2}{bf:tc_adf} {hline 2} Augmented Dickey-Fuller unit-root test

{title:Syntax}

{p 4 8 2}
{cmd:tc_adf} {it:varname} {ifin} [{cmd:,} {opt maxlag(#)} {opt case(nc|c|ct)} {opt criterion(aic|bic)}]

{title:Description}

{pstd}
ADF test with AIC- or BIC-selected augmentation lag. Case
{cmd:nc} = no deterministic terms, {cmd:c} = constant (default),
{cmd:ct} = constant + linear trend.

{title:Stored results}
{pstd}{cmd:r(stat)}  {cmd:r(lags)}  {cmd:r(nobs)}  {cmd:r(cv)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_pp} | {helpb tc_eg} | {helpb tc_es}{p_end}
