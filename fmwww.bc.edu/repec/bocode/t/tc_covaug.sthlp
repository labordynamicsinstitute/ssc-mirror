{smcl}
{title:Title}
{p 4 4 2}{bf:tc_covaug} {hline 2} Covariates-augmented threshold test (Oh, Lee & Meng 2017)

{title:Syntax}
{p 4 8 2}
{cmd:tc_covaug} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt model(tar|mtar)} {opt threshold(#)} {opt maxlag(#)} {opt criterion(aic|bic)}]

{title:Description}
{pstd}
Augments the Enders-Siklos testing equation with the first differences of
the I(1) regressors as stationary covariates, yielding higher power.
Bundles 5%-CV table for m = 1, 2, 3 regressors.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_glsmtar} | {helpb tc_exes}{p_end}
