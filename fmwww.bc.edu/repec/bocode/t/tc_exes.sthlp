{smcl}
{title:Title}
{p 4 4 2}{bf:tc_exes} {hline 2} Extended Enders-Siklos test (Osinska & Galecki 2022)

{title:Syntax}

{p 4 8 2}
{cmd:tc_exes} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt model(tar|mtar)} {opt maxlag(#)} {opt trim(#)} {opt criterion(aic|bic)} {opt threshvar(varname)}]

{title:Description}
{pstd}
Uses an individual stationary variable (default: Δx1) as the threshold
variable instead of the ECM residual.  Optimal threshold is selected by
grid search maximising the Φ statistic over [trim, 1-trim] quantiles.

{title:Stored results}
{pstd}{cmd:r(sup_phi)}  {cmd:r(threshold)}  {cmd:r(rho1)}  {cmd:r(rho2)}
{cmd:r(t_rho1)}  {cmd:r(t_rho2)}  {cmd:r(f_asymmetry)}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_glsmtar} | {helpb tc_covaug} | {helpb tc_bf}{p_end}
