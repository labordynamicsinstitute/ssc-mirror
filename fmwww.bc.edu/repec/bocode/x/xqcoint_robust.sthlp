{smcl}
{* February 2026}{...}
{cmd:help xqcoint_robust}
{hline}

{title:Title}

{phang}
{bf:xqcoint_robust} {hline 2} Robust cointegration test in quantile regressions
based on partial-sum process of ψ_τ residuals (Xiao 2009, Section 3.3).


{title:Syntax}

{p 8 17 2}
{cmd:xqcoint_robust} {depvar} {indepvars} {ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(numlist)}}quantile levels in (0,1); required{p_end}
{synopt :{opt leads(#)}}leads of Δx in augmented regression; default 1{p_end}
{synopt :{opt lags(#)}}lags of Δx in augmented regression; default 1{p_end}
{synopt :{opt band:width(#)}}long-run variance bandwidth; default ceil(2*T^(1/3)){p_end}
{synopt :{opt kern:el(name)}}{cmd:bartlett} (default), {cmd:parzen}, {cmd:qs}{p_end}
{synopt :{opt graph}}plot KS and CVM functionals vs τ{p_end}
{synopt :{opt notab:le}}suppress results table{p_end}
{synopt :{opt saveks(name)}}save KS statistic vector{p_end}
{synopt :{opt savecvm(name)}}save CVM statistic vector{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:xqcoint_robust} implements the robust cointegration test of Xiao (2009)
Section 3.3. For each quantile τ, the augmented quantile regression
(with Saikkonen-style leads/lags of Δx) yields residuals ε̂_t(τ). The
partial-sum process is

{phang2}{it:Y_n(r) = ω̂_ψ⁻¹ · n^(-1/2) · Σ_{j=1}^{[nr]} ψ_τ(ε̂_jτ)}{p_end}

{pstd}
where ψ_τ(u) = τ − I(u < 0). Two functionals are computed:

{phang2}{bf:KS}   = sup_r |Y_n(r)|{p_end}
{phang2}{bf:CVM}  = ∫_0^1 Y_n(r)² dr{p_end}

{pstd}
Under H0 of cointegration, Y_n(r) converges to a centered Gaussian process
(closely related to a Brownian bridge). Under H1 of no cointegration, the
statistics diverge. Reference asymptotic critical values from the
Brownian-bridge approximation: KS at 5% = 1.358, 1% = 1.628;
CVM at 5% = 0.461, 1% = 0.743.

{pstd}
{bf:Note}: Xiao 2009 shows that the EXACT limiting distribution of Y_n(r)
involves stochastic integrals of demeaned Brownian motions and differs
slightly from a Brownian bridge. The CVs reported are conservative.
For exact size, use a Monte Carlo bootstrap. Finite-sample power can be
limited (n ≥ 500 recommended for reliable inference).

{pstd}
This test is DISTINCT from {help xqcoint}'s CUSUM (Kuriyama 2016), which
uses FM-residuals rather than augmented residuals.


{title:Examples}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. xqcoint_robust y x, tau(0.1 0.5 0.9) leads(2) lags(2) graph}{p_end}


{title:Stored results}

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:e(leads)} / {cmd:e(lags)}}augmentation orders{p_end}
{synopt:{cmd:e(ks_cv5)} / {cmd:e(ks_cv1)}}KS critical values{p_end}
{synopt:{cmd:e(cvm_cv5)} / {cmd:e(cvm_cv1)}}CVM critical values{p_end}

{p2col 5 16 18 2: Matrices}{p_end}
{synopt:{cmd:e(ks_set)}}ntau × 1 KS statistics{p_end}
{synopt:{cmd:e(cvm_set)}}ntau × 1 CVM statistics{p_end}


{title:Reference}

{phang}
Xiao, Z. (2009). Quantile cointegrating regression. {it:Journal of Econometrics}
150, 248–260 — Section 3.3.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
{help xqcoint}, {help xqcoint_const}, {help qpolycoint}, {help qcointall}
