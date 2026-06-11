{smcl}
{* *! version 1.0.0  16may2026}{...}
{title:Title}

{p 4 19 2}
{hi:mqqr} {hline 2}  Multivariate Quantile-on-Quantile Regression

{title:Syntax}

{p 8 17 2}
{cmd:mqqr} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opt tau(numlist)}}τ grid (default 0.05(0.05)0.95){p_end}
{synopt:{opt theta(numlist)}}θ grid (default 0.05(0.05)0.95){p_end}
{synopt:{opt piv:ot(varname)}}variable that drives the (τ,θ) grid (default: first regressor){p_end}
{synopt:{opt b:andwidth(#)}}kernel bandwidth (default Silverman){p_end}
{synopt:{opt sav:ing(filename)}}save long-format results .dta{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt nopro:gress}}suppress progress{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:mqqr} extends the Sim-Zhou QQR to multiple regressors.  For each (τ, θ)
pair, all regressors are centred at their θ-quantile and a locally-weighted
quantile regression is fit using kernel weights on the empirical CDF of the
{bf:pivot} variable.{p_end}

{title:Saved dataset format}

{p 4 4 2}Long-format columns: {bf:tau theta variable coef se t p}.{p_end}

{title:Example}

{phang2}{cmd:. mqqr co2 gdp energy ict urban, pivot(gdp) saving(mqq.dta) replace}{p_end}
{phang2}{cmd:. qqheat using mqq.dta, value(coef) variable(gdp) colormap(viridis)}{p_end}
{phang2}{cmd:. qqheat using mqq.dta, value(coef) variable(energy) colormap(parula)}{p_end}

{title:See also}

{p 4 8 2}{help qqr}, {help qqheat}, {help qqtable}{p_end}
