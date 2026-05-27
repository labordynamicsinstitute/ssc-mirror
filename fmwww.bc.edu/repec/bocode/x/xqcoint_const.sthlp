{smcl}
{* February 2026}{...}
{cmd:help xqcoint_const}
{hline}

{title:Title}

{phang}
{bf:xqcoint_const} {hline 2} Constancy test of the cointegrating vector across
quantiles (Xiao 2009, Section 3.2).


{title:Syntax}

{p 8 17 2}
{cmd:xqcoint_const} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(numlist)}}quantile grid in (0,1); default 0.05, 0.10, ..., 0.95{p_end}
{synopt :{opt ngrid(#)}}# of grid points if tau() not given; default 19{p_end}
{synopt :{opt leads(#)}}leads of Δx in augmented regression; default 0{p_end}
{synopt :{opt lags(#)}}lags of Δx in augmented regression; default 0{p_end}
{synopt :{opt band:width(#)}}long-run variance bandwidth{p_end}
{synopt :{opt kern:el(name)}}{cmd:bartlett} (default), {cmd:parzen}, {cmd:qs}{p_end}
{synopt :{opt simreps(#)}}Monte Carlo replications for critical values; default 5000{p_end}
{synopt :{opt graph}}plot V̂_n(τ) process{p_end}
{synopt :{opt notab:le}}suppress results table{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:xqcoint_const} tests whether the cointegrating vector β is constant across
quantiles:

{phang2}{it:H0 : β(τ) = β̄  for all τ ∈ T}    (location-shift cointegration){p_end}
{phang2}{it:H1 : β(τ) varies with τ}              (quantile-dependent cointegration){p_end}

{pstd}
The test process is V̂_n(τ) = (β̂(τ) − β̄)/SE(β̂_OLS), where β̄ is the OLS
cointegrating estimate and SE(β̂_OLS) is the standard OLS standard error.
For one-dimensional β, three functionals are reported:

{phang2}{bf:sup_τ |V̂_n(τ)|}  — supremum statistic{p_end}
{phang2}{bf:KS} = sup_τ |V̂_n(τ)|  (same as sup for one-dim case){p_end}
{phang2}{bf:CVM} = mean_τ V̂_n(τ)²  — Cramer-von Mises analogue{p_end}

{pstd}
For multi-dimensional β (k > 1), the L∞ norm across coefficients at each
τ is used.

{pstd}
{bf:Critical values}: under H0, V̂_n(τ) converges to a centered Gaussian
process (Xiao 2009 Theorem 4). The sup/KS/CVM functionals are simulated
via Monte Carlo of standardized Brownian-bridge draws on the τ grid.
The p-values are exact (within Monte Carlo error).


{title:Examples}

{pstd}Test whether the slope is constant across 5 quantiles:{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. xqcoint_const y x, tau(0.1 0.25 0.5 0.75 0.9)}{p_end}

{pstd}With default 19-point grid (τ = 0.05, ..., 0.95):{p_end}
{phang2}{cmd:. xqcoint_const y x, ngrid(19)}{p_end}

{pstd}With augmented regression and graph:{p_end}
{phang2}{cmd:. xqcoint_const y x, tau(0.1(0.1)0.9) leads(2) lags(2) graph}{p_end}


{title:Stored results}

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:e(sup_stat)} / {cmd:e(ks_stat)} / {cmd:e(cvm_stat)}}test statistics{p_end}
{synopt:{cmd:e(sup_pval)} / {cmd:e(ks_pval)} / {cmd:e(cvm_pval)}}MC p-values{p_end}
{synopt:{cmd:e(ntau)}}# of quantiles{p_end}
{synopt:{cmd:e(simreps)}}# Monte Carlo replications{p_end}

{p2col 5 16 18 2: Matrices}{p_end}
{synopt:{cmd:e(Vhat)}}ntau × k V̂_n process values{p_end}
{synopt:{cmd:e(cv_mat)}}3 × 3 matrix: rows sup/KS/CVM × cols cv5/cv1/pval{p_end}


{title:Reference}

{phang}
Xiao, Z. (2009). Quantile cointegrating regression. {it:Journal of Econometrics}
150, 248–260 — Section 3.2 and Theorem 4.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help xqcoint_robust}, {help qpolycoint}, {help qcointall}
