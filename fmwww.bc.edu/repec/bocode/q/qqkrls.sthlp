{smcl}
{* *! version 1.0.0  16may2026}{...}
{title:Title}

{p 4 19 2}
{hi:qqkrls} {hline 2}  Quantile-on-Quantile Kernel Regularised Least Squares

{title:Syntax}

{p 8 17 2}
{cmd:qqkrls} {it:depvar} {it:indepvar} {ifin} [{cmd:,} {it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opt tau(numlist)}}τ grid (default 0.05(0.05)0.95){p_end}
{synopt:{opt theta(numlist)}}θ grid (default 0.05(0.05)0.95){p_end}
{synopt:{opt min:obs(#)}}min observations per θ-subset (default 20){p_end}
{synopt:{opt nb:oot(#)}}bootstrap replications for SE (default 100){p_end}
{synopt:{opt s:igma(#)}}KRLS bandwidth (default: krls auto){p_end}
{synopt:{opt l:ambda(#)}}KRLS regularisation (default: LOO-CV){p_end}
{synopt:{opt sav:ing(filename)}}save long-format results .dta{p_end}
{synopt:{opt replace}}overwrite existing file{p_end}
{synopt:{opt nopro:gress}}suppress progress{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
Implements Quantile-on-Quantile KRLS from {help qqkrls##refs:Adebayo et al. (2024)}.
For each θ the data are subset to {it:x ≤ x_θ}.  A KRLS model is fit on the
subset, producing one pointwise marginal effect {it:dy/dx} per observation.  The
QQ coefficient {it:β(τ,θ)} is then the τ-quantile of these pointwise effects.
Standard errors are obtained by bootstrapping the τ-quantile.{p_end}

{p 4 4 2}
This command wraps the {help krls} command (Hainmueller & Hazlett, SSC).{p_end}

{title:Saved dataset format}

{p 4 4 2}Columns: {bf:tau theta coef se t p n_sub}.{p_end}

{title:Example}

{phang2}{cmd:. qqkrls co2 gdp, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) saving(qk.dta) replace}{p_end}
{phang2}{cmd:. qqheat using qk.dta, value(coef) colormap(plasma) sigmark}{p_end}

{title:References}{marker refs}

{phang}Adebayo, T.S., Ozkan, O. and Eweade, B.S. (2024).
{it:Journal of Cleaner Production} 440:140832.{p_end}

{phang}Hainmueller, J. and Hazlett, C. (2014).
{it:Political Analysis} 22:143-168.{p_end}

{title:See also}

{p 4 8 2}{help krls},  {help qqr}{p_end}
