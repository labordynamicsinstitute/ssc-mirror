{smcl}
{* February 2026}{...}
{cmd:help tuqcoint}
{hline}

{title:Title}

{phang}
{bf:tuqcoint} {hline 2} Nonparametric quantile cointegration with stationary
covariates (Tu, Liang & Wang 2022) — local-constant kernel estimator.


{title:Syntax}

{p 8 17 2}
{cmd:tuqcoint} {depvar} {it:xvar} {it:zvar} {ifin}{cmd:,}
{opt tau(#)}
[{it:options}]

{phang2}where {it:xvar} is an I(1) regressor and {it:zvar} is a stationary covariate.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(#)}}quantile level in (0,1); required (scalar){p_end}
{synopt :{opt gridx(numlist)}}grid of x values for fitting; default 25 equispaced{p_end}
{synopt :{opt gridz(numlist)}}grid of z values; default 25 equispaced{p_end}
{synopt :{opt ngrid(#)}}number of grid points if grids not given; default 25{p_end}
{synopt :{opt h1(#)}}bandwidth on x; default sd(x)·n^(-1/6){p_end}
{synopt :{opt h2(#)}}bandwidth on z; default sd(z)·n^(-1/5){p_end}
{synopt :{opt kern:el(name)}}{cmd:epan} (default), {cmd:gauss}, or {cmd:uniform}{p_end}
{synopt :{opt graph}}produce m̂(x, z̄_med) curve plot{p_end}
{synopt :{opt notab:le}}suppress table{p_end}
{synopt :{opt save(name)}}save fitted surface to matrix{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:tuqcoint} estimates the unknown quantile function {it:m(x_t, z_t)} in
the nonparametric quantile cointegration model:

{phang2}{it:y_t = m(x_t, z_t) + u_t},   {it:x_t} I(1),   {it:z_t} stationary{p_end}

{pstd}
For each (x_g, z_g) grid point, the local-constant quantile estimator solves:

{phang2}{it:m̂(x_g, z_g) = argmin_α Σ_t ρ_τ(y_t - α) K1((x_t-x_g)/h1) K2((z_t-z_g)/h2)}{p_end}

{pstd}
The solution is the weighted τ-th quantile of {y_t} with product-kernel
weights. Pointwise asymptotic 95% CIs use the Tu et al. (2022) Theorem 2.1
sandwich formula.

{pstd}
{bf:NOTE}: The full bootstrap Kolmogorov-Smirnov specification test of
{help tuqcoint##tu2022:Tu, Liang & Wang (2022)} (Section 3) is computationally
heavy and NOT included in this implementation. For parametric specification
tests, see {help qpolycoint} (linearity Wald) or {help fqardl} with
{cmd:type(qcoint)} (Furno residual test).


{title:Examples}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tuqcoint y x z, tau(0.5) ngrid(20)}{p_end}

{phang2}{cmd:. tuqcoint y x z, tau(0.25) gridx(-5(0.5)5) gridz(0(0.1)1) graph}{p_end}


{title:Reference}

{marker tu2022}{...}
{phang}
Tu, Y., Liang, H.-Y. & Wang, Q. (2022). Nonparametric inference for quantile
cointegrations with stationary covariates.
{it:Journal of Econometrics} 230(2), 453–482.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help qpolycoint}, {help liqcoint_fc}, {help qcointall}
