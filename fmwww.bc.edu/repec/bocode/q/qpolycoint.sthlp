{smcl}
{* February 2026}{...}
{cmd:help qpolycoint}{right: ({stata "ssc help qpolycoint":also see online}) }
{hline}

{title:Title}

{phang}
{bf:qpolycoint} {hline 2} Quantile polynomial cointegration with FM correction
and Wald linearity test (Li, Zheng & Guo 2016).


{title:Syntax}

{p 8 17 2}
{cmd:qpolycoint} {depvar} {indepvars} {ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(numlist)}}quantile levels in (0,1); required, sorted{p_end}
{synopt :{opt p:order(#)}}polynomial order p ∈ {2,...,5}; default 3 (Li 2016 recommend 2 or 3){p_end}
{synopt :{opt band:width(#)}}bandwidth M; default = ceil(2*T^(1/3)){p_end}
{synopt :{opt kern:el(name)}}{cmd:bartlett} (default), {cmd:parzen}, or {cmd:qs}{p_end}
{synopt :{opt graph}}produce combined graph of β̂(τ) and Q(τ){p_end}
{synopt :{opt notab:le}}suppress coefficient table{p_end}
{synopt :{opt notest}}suppress Wald test table{p_end}
{synopt :{opt savecoef(name)}}save coefficient matrix{p_end}
{synopt :{opt savetest(name)}}save Wald-statistic vector{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:qpolycoint} implements the polynomial quantile cointegration model of
{help qpolycoint##li2016:Li, Zheng & Guo (2016)}:

{phang2}{it:Q_y_t(τ|x_t) = α + β(τ)'x_t + Σ_{j=2}^p γ_j(τ)'(x_t)^j + F⁻¹(τ)}{p_end}

{pstd}
The polynomial regressors (x_t)^j capture nonlinear long-run relationships.
The fully-modified estimator removes endogeneity bias following Phillips & Hansen
(1990). A Wald-type test for linearity is provided:

{phang2}{it:H_0 : γ_2(τ) = ... = γ_p(τ) = 0}    (linear cointegration){p_end}
{phang2}{it:H_1 : at least one γ_j(τ) ≠ 0}      (nonlinear){p_end}

{pstd}
Under H_0, the Wald statistic Q ⇒ χ²_{k(p-1)} where k is the number of I(1)
regressors. Critical values are computed automatically.


{title:Examples}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. qpolycoint y x, tau(0.25 0.5 0.75)}{p_end}

{phang2}{cmd:. qpolycoint y x, tau(0.1 0.5 0.9) porder(2) graph}{p_end}


{title:Stored results}

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}
{synopt:{cmd:e(porder)}}polynomial order{p_end}
{synopt:{cmd:e(k)}}number of I(1) regressors{p_end}
{synopt:{cmd:e(nrestr)}}# Wald restrictions = k·(p-1){p_end}
{synopt:{cmd:e(bandwidth)}}bandwidth M{p_end}
{synopt:{cmd:e(cv5_q) / e(cv1_q)}}χ² critical values{p_end}

{p2col 5 16 18 2: Matrices}{p_end}
{synopt:{cmd:e(coef_set)}}ntau × (1 + kp) FM polynomial coefficients{p_end}
{synopt:{cmd:e(tQ_set)}}ntau × 1 Wald linearity statistics{p_end}
{synopt:{cmd:e(pval_set)}}ntau × 1 p-values{p_end}
{synopt:{cmd:e(fm_se)}}ntau × (1 + kp) FM standard errors{p_end}


{title:Reference}

{marker li2016}{...}
{phang}
Li, H., Zheng, C. & Guo, Y. (2016). Estimation and test for quantile nonlinear
cointegrating regression. {it:Economics Letters} 148, 27–32.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help tuqcoint}, {help liqcoint_fc}, {help qcointall}, {help fqardl}
