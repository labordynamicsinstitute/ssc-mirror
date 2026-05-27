{smcl}
{* February 2026}{...}
{cmd:help xqcoint}{right: ({stata "ssc help xqcoint":also see online}) }
{hline}

{title:Title}

{phang}
{bf:xqcoint} {hline 2} Fully-modified quantile cointegrating regression (Xiao 2009) and
CUSUM cointegration test (Kuriyama 2016).


{title:Syntax}

{p 8 17 2}
{cmd:xqcoint} {depvar} {indepvars} {ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tau(numlist)}}quantile levels in (0,1); required, sorted{p_end}
{synopt :{opt band:width(#)}}bandwidth M; default = ceil(2*T^(1/3)){p_end}
{synopt :{opt kern:el(name)}}{cmd:bartlett} (default), {cmd:parzen}, or {cmd:qs}{p_end}
{synopt :{opt leads(#)}}# of leads of Δx in augmented regression (Xiao 2009 eq 11){p_end}
{synopt :{opt lags(#)}}# of lags of Δx in augmented regression{p_end}
{synopt :{opt waldtest(numlist)}}joint Wald test H0: β(τ) = listed values (k values){p_end}
{synopt :{opt graph}}produce combined graph of {bf:β̂(τ)} and CUSUM(τ){p_end}
{synopt :{opt notab:le}}suppress the coefficient table{p_end}
{synopt :{opt nocusum}}suppress the CUSUM test table{p_end}
{synopt :{opt savebeta(name)}}save FM coefficient matrix to {it:name}{p_end}
{synopt :{opt savecs(name)}}save CUSUM statistic vector to {it:name}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:xqcoint} implements the fully-modified quantile cointegrating regression
estimator of {help xqcoint##xiao2009:Xiao (2009)} and the CUSUM cointegration
test of {help xqcoint##kuriyama2016:Kuriyama (2016)}.

{pstd}
For each user-supplied quantile τ in (0,1), the command:{p_end}
{phang2}1. Estimates the quantile regression {it:y_t = α(τ) + β(τ)'x_t + u_t(τ)} via interior-point;{p_end}
{phang2}2. Applies a Phillips-Hansen-type fully modified correction using the
   Bartlett kernel with plug-in bandwidth M = 2·T^(1/3), producing {it:β̂⁺(τ)};{p_end}
{phang2}3. Computes the CUSUM statistic
   {it:CS_T(τ) = max_n |Σ_t=1^n ψ_τ(û_t⁺)| / (ω̂_ψ.x · √T)};{p_end}
{phang2}4. Compares CS_T(τ) to {help xqcoint##haoinder1996:Hao-Inder (1996)}
   Table 1 critical values (k regressors, no trend).{p_end}

{pstd}
Under H0 of cointegration, CS_T(τ) ⇒ sup_r |W(r)|; under no cointegration,
the statistic diverges. Critical values:

{phang2}{c TLC}{hline 4}{c -}{hline 9}{c -}{hline 9}{c -}{hline 9}{c TRC}{p_end}
{phang2}{c |}  k  {c |}   10%  {c |}    5%  {c |}    1%  {c |}{p_end}
{phang2}{c |}  1  {c |}  1.0477{c |}  1.1684{c |}  1.4255{c |}{p_end}
{phang2}{c |}  2  {c |}  1.0980{c |}  1.2238{c |}  1.4884{c |}{p_end}
{phang2}{c |}  3  {c |}  1.1318{c |}  1.2611{c |}  1.5326{c |}{p_end}
{phang2}{c BLC}{hline 4}{c -}{hline 9}{c -}{hline 9}{c -}{hline 9}{c BRC}{p_end}


{title:Examples}

{pstd}Default FMQR (Phillips-Hansen FM correction):{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.25 0.5 0.75)}{p_end}

{pstd}Augmented FM-QR (Saikkonen leads/lags, Xiao 2009 eq 11):{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.25 0.5 0.75) leads(2) lags(2)}{p_end}

{pstd}Joint Wald test H0: β(τ) = 1:{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.1 0.5 0.9) waldtest(1)}{p_end}

{pstd}Multi-regressor joint Wald H0: (β1, β2) = (0.5, -0.3):{p_end}
{phang2}{cmd:. xqcoint y x1 x2, tau(0.5) waldtest(0.5 -0.3) graph}{p_end}


{title:Stored results}

{pstd}{cmd:xqcoint} stores the following in {cmd:e()}:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 18 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}
{synopt:{cmd:e(k)}}number of I(1) regressors{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(bandwidth)}}bandwidth M used{p_end}
{synopt:{cmd:e(cv5)} / {cmd:e(cv1)}}5%/1% Hao-Inder critical values{p_end}

{p2col 5 16 18 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xqcoint}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}I(1) regressors{p_end}
{synopt:{cmd:e(kernel)}}kernel name{p_end}
{synopt:{cmd:e(tau)}}quantile list{p_end}

{p2col 5 16 18 2: Matrices}{p_end}
{synopt:{cmd:e(beta_set)}}ntau × k FM slope coefficients{p_end}
{synopt:{cmd:e(t_set)}}ntau × k t-statistics for β̂⁺ = 0{p_end}
{synopt:{cmd:e(alpha_set)}}ntau × 1 FM intercepts{p_end}
{synopt:{cmd:e(cs_set)}}ntau × 1 CUSUM statistics{p_end}
{synopt:{cmd:e(rej05)} / {cmd:e(rej01)}}ntau × 1 CUSUM rejection indicators{p_end}
{synopt:{cmd:e(wald_set)}}ntau × 1 Wald statistics (if {cmd:waldtest()} given){p_end}
{synopt:{cmd:e(wald_pval)}}ntau × 1 Wald p-values{p_end}

{p2col 5 16 18 2: Additional macros}{p_end}
{synopt:{cmd:e(method)}}{cmd:FMQR} or {cmd:Augmented FM-QR}{p_end}


{title:References}

{marker xiao2009}{...}
{phang}
Xiao, Z. (2009). Quantile cointegrating regression.
{it:Journal of Econometrics} 150, 248–260.

{marker kuriyama2016}{...}
{phang}
Kuriyama, N. (2016). Testing cointegration in quantile regressions with an
application to the term structure of interest rates.
{it:Studies in Nonlinear Dynamics & Econometrics} 20(2), 107–121.

{marker haoinder1996}{...}
{phang}
Hao, K. & Inder, B. (1996). Diagnostic test for structural change in
cointegrated regression models. {it:Economics Letters} 50, 179–187.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:Also see}

{psee}
Related commands:
{help qpolycoint}, {help tuqcoint}, {help liqcoint_fc}, {help qcointall},
{help fqardl}, {help qardl}
