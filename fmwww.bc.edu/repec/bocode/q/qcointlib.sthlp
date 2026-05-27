{smcl}
{* February 2026}{...}
{cmd:help qcointlib}
{hline}

{title:Title}

{phang}
{bf:qcointlib} {hline 2} Stata library for quantile cointegration analysis:
estimators and tests covering the modern literature (Xiao 2009, Kuriyama 2016,
Li-Zheng-Guo 2016, Furno 2020, Cho-Kim-Shin 2015, Tu-Liang-Wang 2022,
Li-Zhang-Zheng 2025).


{title:Overview}

{pstd}
{cmd:qcointlib} is a unified, dependency-free implementation in Stata/Mata of
the quantile cointegration framework. It provides:

{phang2}- {bf:Eight estimators} (FMQR, Median/LAD, Augmented FM-QR, Polynomial QR,
NP local-constant, Functional-coefficient LLQR, NFMQR, QARDL via SSC){p_end}

{phang2}- {bf:Twelve hypothesis tests} (CUSUM, Furno aux-QR, Wald, KS, CVM,
Sup, Constancy, Linearity, etc.){p_end}

{phang2}- {bf:A master command} that runs the whole battery with one call and
exports publication-quality graphs.{p_end}


{title:Commands}

{pstd}
Click any command name to open its help page:

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt:{helpb xqcoint}}FMQR (Xiao 2009) + CUSUM (Kuriyama 2016) + augmented option + Wald test{p_end}
{synopt:{helpb xqcoint_robust}}Robust cointegration test: Y_n(r) partial-sum with KS and CVM functionals (Xiao 2009 §3.3){p_end}
{synopt:{helpb xqcoint_const}}Constancy test of β(τ): sup, KS, CVM functionals with Monte-Carlo CVs (Xiao 2009 §3.2){p_end}
{synopt:{helpb qpolycoint}}Polynomial quantile cointegration + Wald linearity test (Li, Zheng & Guo 2016){p_end}
{synopt:{helpb tuqcoint}}Nonparametric local-constant quantile cointegration with stationary covariate (Tu, Liang & Wang 2022){p_end}
{synopt:{helpb liqcoint_fc}}Functional-coefficient QR cointegration + NFMQR option (Li, Zhang & Zheng 2025){p_end}
{synopt:{helpb qcointall}}Master command — runs every estimator/test and produces a combined verdict table{p_end}
{synoptline}

{pstd}
Companion commands (already in your installation):

{synoptset 22 tabbed}{...}
{synopt:{helpb fqardl}}Fourier Quantile ARDL; {cmd:type(qcoint)} runs the Furno (2020) aux-QR test{p_end}
{synopt:{helpb qardl}}Cho, Kim & Shin (2015) QARDL with constancy Wald tests (SSC){p_end}
{synoptline}


{title:Paper-to-command map}

{synoptset 28 tabbed}{...}
{synopthdr:reference}
{synoptline}
{synopt:Xiao (2009)}{helpb xqcoint}, {helpb xqcoint_robust}, {helpb xqcoint_const}{p_end}
{synopt:Kuriyama (2016)}{helpb xqcoint} (CUSUM table){p_end}
{synopt:Li, Zheng & Guo (2016)}{helpb qpolycoint}{p_end}
{synopt:Furno (2020)}{helpb fqardl}{cmd: , type(qcoint)}{p_end}
{synopt:Cho, Kim & Shin (2015)}{helpb qardl} (SSC){p_end}
{synopt:Tu, Liang & Wang (2022)}{helpb tuqcoint}{p_end}
{synopt:Li, Zhang & Zheng (2025)}{helpb liqcoint_fc}{p_end}
{synopt:All of the above}{helpb qcointall} (master){p_end}
{synoptline}


{title:Quick start}

{pstd}Set up time-series data:{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Run everything at once with tables and PNG graphs:{p_end}
{phang2}{cmd:. qcointall y x, tau(0.1 0.25 0.5 0.75 0.9) full}{p_end}

{pstd}Add a stationary covariate to enable {help tuqcoint} and {help liqcoint_fc}:{p_end}
{phang2}{cmd:. qcointall y x, tau(0.1 0.25 0.5 0.75 0.9) zvar(z) full}{p_end}

{pstd}Individual estimators:{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.25 0.5 0.75) graph}                  {it:// basic FMQR + CUSUM}{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.25 0.5 0.75) leads(2) lags(2)}       {it:// augmented FM-QR}{p_end}
{phang2}{cmd:. xqcoint y x, tau(0.1 0.5 0.9) waldtest(1)}              {it:// joint H0: β = 1}{p_end}
{phang2}{cmd:. xqcoint_robust y x, tau(0.1 0.5 0.9) graph}             {it:// KS / CVM test}{p_end}
{phang2}{cmd:. xqcoint_const y x, ngrid(19) graph}                     {it:// constancy of β(τ)}{p_end}
{phang2}{cmd:. qpolycoint y x, tau(0.25 0.5 0.75) porder(3) graph}     {it:// linearity test}{p_end}
{phang2}{cmd:. tuqcoint y x z, tau(0.5) ngrid(20) graph}               {it:// NP m̂(x,z)}{p_end}
{phang2}{cmd:. liqcoint_fc y x, tau(0.5) zvar(z) fm graph}             {it:// NFMQR β̂(z)}{p_end}


{title:What is quantile cointegration?}

{pstd}
A classical cointegrating regression assumes a constant long-run relationship:
{it:y_t = α + β'x_t + u_t}, with {it:y_t} and {it:x_t} both I(1) and {it:u_t}
stationary. {bf:Quantile cointegration} extends this to allow the
cointegrating vector {it:β(τ)} to depend on the conditional quantile of {it:y_t}:

{phang2}{it:Q_y(τ|x_t) = α(τ) + β(τ)'x_t + F⁻¹(τ)}{p_end}

{pstd}
This captures asymmetric long-run dynamics — useful when the slope at low
quantiles differs from the slope at high quantiles (financial markets,
interest-rate spreads, asymmetric price adjustment). Each command in this
library targets a different angle of this framework: linear vs polynomial vs
nonparametric vs functional-coefficient, with the FM (Phillips-Hansen)
correction for endogeneity in I(1) regressors.


{title:Installation}

{pstd}
From SSC:{p_end}
{phang2}{cmd:. ssc install qcointlib}{p_end}

{pstd}
This installs all eight {cmd:.ado} files and corresponding help pages into
your Stata personal ado path.


{title:Stored results}

{pstd}
Each command stores its specific results in {cmd:e()} (or {cmd:r()} in the
case of {cmd:qcointall}); see the individual help pages for details. Typical
matrices include β̂(τ) across quantiles, test statistics, p-values, and
critical values.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
February 2026


{title:References}

{phang}Cho, J. S., Kim, T.-h. & Shin, Y. (2015). Quantile cointegration in the
autoregressive distributed-lag modeling framework. {it:Journal of Econometrics}
188, 281–300.

{phang}Furno, M. (2020). Cointegration tests at the quantiles.
{it:International Journal of Finance & Economics} 27, 1097–1110.

{phang}Hao, K. & Inder, B. (1996). Diagnostic test for structural change in
cointegrated regression models. {it:Economics Letters} 50, 179–187.

{phang}Kuriyama, N. (2016). Testing cointegration in quantile regressions with
an application to the term structure of interest rates.
{it:Studies in Nonlinear Dynamics & Econometrics} 20, 107–121.

{phang}Li, H., Zheng, C. & Guo, Y. (2016). Estimation and test for quantile
nonlinear cointegrating regression. {it:Economics Letters} 148, 27–32.

{phang}Li, H., Zhang, J. & Zheng, C. (2025). Functional-coefficient quantile
cointegrating regression with stationary covariates.
{it:Statistics and Probability Letters} 219, 110344.

{phang}Phillips, P. C. B. & Hansen, B. E. (1990). Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies} 57, 99–125.

{phang}Tu, Y., Liang, H.-Y. & Wang, Q. (2022). Nonparametric inference for
quantile cointegrations with stationary covariates.
{it:Journal of Econometrics} 230, 453–482.

{phang}Xiao, Z. (2009). Quantile cointegrating regression.
{it:Journal of Econometrics} 150, 248–260.


{title:Also see}

{psee}
{help xqcoint}, {help xqcoint_robust}, {help xqcoint_const},
{help qpolycoint}, {help tuqcoint}, {help liqcoint_fc}, {help qcointall},
{help fqardl}, {help qardl}
