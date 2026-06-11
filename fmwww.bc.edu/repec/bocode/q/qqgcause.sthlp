{smcl}
{* *! version 1.0.0  16may2026}{...}
{title:Title}

{p 4 19 2}
{hi:qqgcause} {hline 2}  Nonparametric Quantile Granger Causality

{title:Syntax}

{p 8 17 2}
{cmd:qqgcause} {it:effect} {it:cause} {ifin} [{cmd:,} {it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opt tau(numlist)}}τ grid (default 0.05(0.05)0.95){p_end}
{synopt:{opt type(string)}}{cmd:mean} or {cmd:variance} (default {cmd:mean}){p_end}
{synopt:{opt b:andwidth(#)}}base bandwidth (Silverman by default){p_end}
{synopt:{opt sav:ing(filename)}}save results .dta{p_end}
{synopt:{opt replace}}overwrite{p_end}
{synopt:{opt nopro:gress}}suppress progress{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
Implements the nonparametric quantile Granger-causality test of
{help qqgcause##refs:Jeong, Härdle & Song (2012)} as adapted by Balcilar et al. (2016).
Tests whether {it:cause_{t-1}} Granger-causes {it:effect_t} in the τ-quantile.
{cmd:type(variance)} tests second-moment (volatility) spillover.{p_end}

{p 4 4 2}
Under H₀ (no causality), the statistic is asymptotically N(0,1).
Critical values:  10% = 1.645,  5% = 1.96,  1% = 2.58.{p_end}

{title:Saved dataset format}

{p 4 4 2}Columns: {bf:tau tstat p sig5 sig1}.{p_end}

{title:Example}

{phang2}{cmd:. qqgcause sp500 oil, saving(cause.dta) replace}{p_end}
{phang2}{cmd:. qqcauseplot using cause.dta, title("Oil -> S&P 500")}{p_end}
{phang2}{cmd:. qqgcause sp500 oil, type(variance) saving(cause_var.dta) replace}{p_end}

{title:References}{marker refs}

{phang}Jeong, Härdle & Song (2012). {it:Econometric Theory} 28(4).{p_end}
{phang}Balcilar et al. (2016). {it:Resources Policy} 49.{p_end}

{title:See also}

{p 4 8 2}{help qqcauseplot},  {help qqr}{p_end}
