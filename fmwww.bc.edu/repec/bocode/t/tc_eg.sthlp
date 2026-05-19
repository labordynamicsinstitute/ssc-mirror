{smcl}
{title:Title}

{p 4 4 2}{bf:tc_eg} {hline 2} Engle-Granger residual-based cointegration test

{title:Syntax}

{p 4 8 2}
{cmd:tc_eg} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt maxlag(#)} {opt case(nc|c|ct)} {opt criterion(aic|bic)}]

{title:Description}
{pstd}
Two-step Engle-Granger procedure: (1) OLS cointegrating regression,
(2) ADF on residuals.  Uses MacKinnon-style critical values that depend
on the number of regressors {it:m} (1-4 tabulated).

{title:Stored results}
{pstd}{cmd:r(stat)}  {cmd:r(lags)}  {cmd:r(nobs)}  {cmd:r(m)}
{cmd:r(cv)}  {cmd:r(coint_vec)}

{title:After-command:}
{phang}{cmd:predict} {it:newvar}{cmd:, residual} is not available; use
{cmd:reg depvar indepvars; predict resid, residual} instead, or read
{cmd:r(coint_vec)} and compute residuals manually.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adf} | {helpb tc_pp} | {helpb tc_es} | {helpb tc_glsmtar} | {helpb tc_bf}{p_end}
