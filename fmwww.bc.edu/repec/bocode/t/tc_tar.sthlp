{smcl}
{title:Title}
{p 4 4 2}{bf:tc_tar} {hline 2} TAR / MTAR model fit on cointegrating residuals

{title:Syntax}
{p 4 8 2}
{cmd:tc_tar} {it:resvar} {ifin} [{cmd:,} {opt model(tar|mtar)} {opt threshold(#)} {opt maxlag(#)} {opt criterion(aic|bic)}]

{title:Description}
{pstd}
Fits the two-regime TAR / MTAR adjustment model on the residual series
from a cointegrating regression (use {help tc_eg} first, then
{cmd:predict resid, residual}).

{title:Stored results}
{pstd}{cmd:r(phi_stat)} {cmd:r(rho1)} {cmd:r(rho2)} {cmd:r(t_rho1)} {cmd:r(t_rho2)} {cmd:r(f_asymmetry)} {cmd:r(threshold)} {cmd:r(lags)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_eqtar} | {helpb tc_setar} | {helpb tc_plot}{p_end}
