{smcl}
{* February 2026}{...}
{cmd:help liqcoint_fc}
{hline}

{title:Title}

{phang}
{bf:liqcoint_fc} {hline 2} Functional-coefficient quantile cointegrating regression
with stationary covariates (Li, Zhang & Zheng 2025).


{title:Syntax}

{p 8 17 2}
{cmd:liqcoint_fc} {depvar} {indepvars} {ifin}{cmd:,}
{opt tau(#)} {opt z:var(varname)}
[{it:options}]

{phang2}where {it:indepvars} are I(1) regressors and {it:zvar} is a stationary covariate.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(#)}}quantile level in (0,1); required (scalar){p_end}
{synopt :{opt z:var(varname)}}stationary covariate {it:z_t}; required{p_end}
{synopt :{opt gridz(numlist)}}grid of z values; default 25 equispaced{p_end}
{synopt :{opt ngrid(#)}}number of grid points; default 25{p_end}
{synopt :{opt band:width(#)}}bandwidth h; default 1.06·sd(z)·n^(-1/5){p_end}
{synopt :{opt kern:el(name)}}{cmd:epan} (default), {cmd:gauss}, or {cmd:uniform}{p_end}
{synopt :{opt fm}}apply NFMQR (Nonparametric Fully-Modified) endogeneity correction (Li 2025 eq 2.7){p_end}
{synopt :{opt graph}}plot β̂(z) curves with 95% CIs{p_end}
{synopt :{opt notab:le}}suppress table{p_end}
{synopt :{opt save(name)}}save β̂(z) matrix{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:liqcoint_fc} fits the functional-coefficient quantile cointegration model
of {help liqcoint_fc##li2025:Li, Zhang & Zheng (2025)}:

{phang2}{it:y_t = α + x_t' β(τ, z_t) + u_t}{p_end}

{pstd}
where the coefficient {it:β(τ, z)} is an unknown smooth function of the
stationary covariate {it:z_t}. For each grid point z_0, a local-linear quantile
regression is fitted:

{phang2}{it:β̂(z_0) = argmin_b Σ_t ρ_τ(y_t - x_t'(b_0 + b_1·(z_t-z_0))) · K((z_t-z_0)/h)}{p_end}

{pstd}
Pointwise 95% confidence intervals use the asymptotic sandwich variance
(Cai, Li & Park 2009 / Li et al. 2025 Theorem 1).

{pstd}
{bf:NOTE}: The double-sup Kolmogorov-Smirnov stability test with
fixed-regressor wild bootstrap (Li et al. 2025 Section 3 and Theorem 4) is
NOT included in this implementation. For parametric structural tests, see
{help qpolycoint} or {help fqardl} with {cmd:type(qcoint)}.


{title:Examples}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. liqcoint_fc y x, tau(0.5) zvar(z) ngrid(20) graph}{p_end}

{phang2}{cmd:. liqcoint_fc y x1 x2, tau(0.25) zvar(zindex) gridz(0(0.1)1)}{p_end}


{title:Reference}

{marker li2025}{...}
{phang}
Li, H., Zhang, J. & Zheng, C. (2025). Functional-coefficient quantile
cointegrating regression with stationary covariates.
{it:Statistics and Probability Letters} 219, 110344.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help qpolycoint}, {help tuqcoint}, {help qcointall}
