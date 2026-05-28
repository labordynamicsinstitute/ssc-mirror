{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Overview"       "dnqrlib##overview"}{...}
{viewerjumpto "Commands"       "dnqrlib##commands"}{...}
{viewerjumpto "Workflow"       "dnqrlib##workflow"}{...}
{viewerjumpto "References"     "dnqrlib##references"}{...}
{viewerjumpto "Author"         "dnqrlib##author"}{...}
{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :{bf:dnqrlib} {hline 2}}Network Quantile Autoregression and Dynamic Network Quantile Regression{p_end}
{p2colreset}{...}


{marker overview}{...}
{title:Overview}

{pstd}
The {bf:dnqr} package provides Stata implementations of two complementary
network quantile time-series models:

{phang2}{bf:1.} {ul:Network Quantile Autoregression} (NQAR) of
Zhu, Wang, Wang and H{c a:}rdle (2019).  Only {it:lagged} network spillovers
enter the conditional quantile, so the model is estimated by plain
quantile regression.  See {help nqar:nqar}.{p_end}

{phang2}{bf:2.} {ul:Dynamic Network Quantile Regression} (DNQR) of
Xu, Wang, Shin and Zheng (2024).  The model adds a {it:contemporaneous}
network mean Gamma{sub:1}(tau) {it:WY{sub:t}}, which is endogenous and
estimated by Chernozhukov-Hansen instrumental variable quantile regression
(IVQR) via a one-dimensional grid search.  See {help dnqr:dnqr}.{p_end}

{pstd}
Both estimators accept a row-standardised N x N adjacency matrix {it:W}
passed as a Stata or Mata matrix, optional time-invariant nodal covariates
{it:Z}, and optional common factors {it:F} with lags.  Standard errors are
Powell (1986) sandwich with Hall-Sheather or Bofinger bandwidth following
Koenker and Xiao (2006), so no bootstrap is required.  The full package
runs in Stata 13 and above and depends only on built-in {help qreg:qreg}
(no Stata 18+ {help ivqregress} required).


{marker commands}{...}
{title:Commands in this package}

{p2colset 5 32 38 2}{...}
{p2col :{help nqar:nqar}}Network Quantile Autoregression (Zhu et al. 2019){p_end}
{p2col :{help dnqr:dnqr}}Dynamic Network Quantile Regression (Xu et al. 2024){p_end}
{p2col :{help dnqr_plot:dnqr_plot}}Plot quantile coefficient processes with CI bands{p_end}
{p2col :{help dnqr_impulse:dnqr_impulse}}Tail-event impulse-response analysis{p_end}
{p2col :{help dnqr_simulate:dnqr_simulate}}Monte Carlo data simulator{p_end}
{p2col :{help dnqr_postestimation:dnqr_postestimation}}All post-estimation tools{p_end}
{p2colreset}{...}


{marker workflow}{...}
{title:Typical workflow}

{phang}{cmd}. * 1. simulate a panel and a network{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(80) t(60) gamma1(0.25) gamma2(0.20) gamma3(0.30) z(2) factors(2) clear wname(W){p_end}

{phang}{cmd}. * 2. fit the NQAR baseline (no contemporaneous term){txt}{p_end}
{phang}{cmd}. nqar y, network(W) quantile(0.1 0.25 0.5 0.75 0.9) z(Z1 Z2) factors(F1 F2) rowstd{p_end}

{phang}{cmd}. * 3. fit the full DNQR with contemporaneous network endogeneity{txt}{p_end}
{phang}{cmd}. dnqr y, network(W) quantile(0.1 0.25 0.5 0.75 0.9) z(Z1 Z2) factors(F1 F2) rowstd ivtype(wy23){p_end}

{phang}{cmd}. * 4. plot the quantile process{txt}{p_end}
{phang}{cmd}. dnqr_plot WY WY_L1 Y_L1{p_end}

{phang}{cmd}. * 5. tail-event impulse response at tau = 0.9{txt}{p_end}
{phang}{cmd}. dnqr_impulse, network(W) rowstd horizon(10) quantile(0.9) shocknode(1) plot{p_end}


{marker references}{...}
{title:References}

{phang}
Chernozhukov, V., and C. Hansen. 2006. Instrumental quantile regression
inference for structural and treatment effect models. {it:Journal of
Econometrics} 132: 491-525.

{phang}
Koenker, R., and Z. Xiao. 2006. Quantile autoregression. {it:Journal of
the American Statistical Association} 101: 980-990.

{phang}
Powell, J. L. 1986. Censored regression quantiles. {it:Journal of
Econometrics} 32: 143-155.

{phang}
Xu, X., W. Wang, Y. Shin, and C. Zheng. 2024. {it:Dynamic Network
Quantile Regression Model}. SSRN Working Paper 3690631.

{phang}
Zhu, X., W. Wang, H. Wang, and W. K. H{c a:}rdle. 2019. Network quantile
autoregression. {it:Journal of Econometrics} 212(1): 345-358.


{marker author}{...}
{title:Author}

{pstd}{bf:Dr Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Version: 1.0.0, 27 May 2026{p_end}

{pstd}
The package is distributed as is, without warranty.  Bug reports and
suggestions for new features are welcome at the email above.{p_end}
