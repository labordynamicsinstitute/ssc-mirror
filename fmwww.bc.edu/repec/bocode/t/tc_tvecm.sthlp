{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_tvecm} {hline 2} Threshold Vector Error-Correction Model (2 regimes)

{title:Syntax}

{p 4 8 2}
{cmd:tc_tvecm} {it:y1var} {it:y2var} {ifin} [{cmd:,} {opt lag(#)} {opt trim(#)} {opt beta(#)} {opt ngrid(#)} {opt saveect(name)}]

{title:Description}

{pstd}
Estimates a 2-regime threshold VECM by minimising the total SSR (sum across
equations) over a grid of ECT thresholds.  If {opt beta(#)} is not given, the
cointegrating coefficient is estimated by OLS of {it:y1} on {it:y2}.

{title:Stored results}
{pstd}{cmd:r(threshold)}, {cmd:r(beta_est)}, {cmd:r(lag)}, {cmd:r(nregime1)}, {cmd:r(nregime2)}, {cmd:r(ssr)}, {cmd:r(ect)} (column vector of the ECT lagged once).

{title:Example}
{phang}{stata "tc_tvecm ln_inv ln_inc, lag(1) trim(0.05) ngrid(300)"}{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_hs} | {helpb tc_sysadl} | {helpb tc_setar} | {helpb tc_plot}{p_end}
