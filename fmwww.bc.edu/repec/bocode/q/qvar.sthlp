{smcl}
{* *! version 1.0.0  07may2026}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "qvar##syntax"}{...}
{viewerjumpto "Description" "qvar##description"}{...}
{viewerjumpto "Options" "qvar##options"}{...}
{viewerjumpto "Subcommands" "qvar##subcommands"}{...}
{viewerjumpto "Examples" "qvar##examples"}{...}
{viewerjumpto "Stored results" "qvar##results"}{...}
{viewerjumpto "References" "qvar##references"}{...}
{viewerjumpto "Author" "qvar##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:qvar} {hline 2}}Quantile Vector Autoregression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:qvar} {it:subcommand} [{varlist}] [{cmd:,} {it:options}]

{pstd}
where {it:subcommand} is one of

{p2colset 9 28 30 2}{...}
{p2col:{opt estimate}}estimate QVAR model equation-by-equation via quantile regression{p_end}
{p2col:{opt granger}}quantile Granger causality with instability detection{p_end}
{p2col:{opt varqr}}two-stage VAR-QR Growth-at-Risk model{p_end}
{p2col:{opt forecast}}multi-step quantile forecasting via simulation{p_end}
{p2col:{opt irf}}quantile impulse response functions{p_end}
{p2col:{opt evaluate}}forecast evaluation (qwCRPS, Diebold-Mariano, coverage){p_end}
{p2col:{opt plot}}publication-quality visualizations{p_end}
{p2col:{opt table}}formatted output tables (console, LaTeX, HTML){p_end}
{p2colreset}{...}

{pstd}
{ul:Subcommand syntax}

{phang}
{bf:qvar estimate} {varlist} {cmd:,} {opt lags(#)} [{opt taus(numlist)} {opt rec:ursive} {opt norec:ursive} {opt maxiter(#)} {opt tol:erance(#)}]

{phang}
{bf:qvar granger} {it:depvar gcvar} {cmd:,} {opt lags(#)} [{opt con:trols(varlist)} {opt boot:strap(#)} {opt reg:imes} {opt noreg:imes} {opt alpha(#)} {opt supwald} {opt nosupwald} {opt taugrid(numlist)}]

{phang}
{bf:qvar varqr} {varlist} {cmd:,} {opt varlags(#)} [{opt qrlags(#)} {opt taus(numlist)}]

{phang}
{bf:qvar forecast} {cmd:,} {opt hor:izon(#)} [{opt nsims(#)} {opt seed(#)} {opt stress(string)} {opt var:iable(string)}]

{phang}
{bf:qvar irf} {cmd:,} {opt shockvar(varname)} [{opt shocksize(#)} {opt hor:izon(#)} {opt taupath(numlist)} {opt nboot(#)} {opt seed(#)} {opt com:pare(numlist)}]

{phang}
{bf:qvar evaluate} {varlist} {cmd:,} {opt actual(varname)} [{opt taus(numlist)} {opt wei:ght(string)} {opt hor:izon(#)} {opt nom:inal(#)}]

{phang}
{bf:qvar plot} {it:plottype} [{cmd:,} {it:plot_options}]

{phang}
{bf:qvar table} {it:tabletype} [{cmd:,} {it:table_options}]


{marker options}{...}
{title:Options}

{dlgtab:estimate options}

{phang}
{opt lags(#)} specifies the number of lags in the QVAR system. Required.

{phang}
{opt taus(numlist)} specifies the quantile levels at which to estimate.
Default is {cmd:0.05 0.25 0.50 0.75 0.95}.

{phang}
{opt recursive} imposes a recursive (lower-triangular) contemporaneous
structure on the QVAR, where the ordering of variables in {varlist}
determines the Cholesky identification. This is the default.

{phang}
{opt norecursive} omits contemporaneous regressors so that each equation
depends only on lagged values.

{phang}
{opt maxiter(#)} sets the maximum number of QR iterations. Default is {cmd:1000}.

{phang}
{opt tolerance(#)} sets the QR convergence tolerance. Default is {cmd:1e-6}.

{dlgtab:granger options}

{phang}
{opt lags(#)} specifies the number of lags of the Granger-causing variable. Required.

{phang}
{opt controls(varlist)} specifies additional control variables to include
in both the restricted and unrestricted quantile regressions.

{phang}
{opt bootstrap(#)} specifies the number of bootstrap replications for
computing p-values. Default is {cmd:499}.

{phang}
{opt regimes} requests sequential regime detection (Algorithm 2 of
Mayer, Wied & Troster, 2025). This is the default.

{phang}
{opt noregimes} skips the regime detection step.

{phang}
{opt alpha(#)} specifies the significance level for regime detection.
Default is {cmd:0.10}.

{phang}
{opt supwald} computes the supWald comparison test of Koenker & Machado (1999).
This is the default.

{phang}
{opt nosupwald} skips the supWald computation to save time.

{phang}
{opt taugrid(numlist)} specifies the quantile grid over which to compute
the test statistics. Default is {cmd:0.05(0.01)0.95}.

{dlgtab:varqr options}

{phang}
{opt varlags(#)} specifies the number of lags for the Stage 1 OLS VAR. Required.

{phang}
{opt qrlags(#)} specifies the number of lags for the Stage 2 quantile
regression on VAR residuals. Default is {cmd:1}.

{phang}
{opt taus(numlist)} specifies the quantiles for the residual QR stage.
Default is {cmd:0.10 0.90}.

{dlgtab:forecast options}

{phang}
{opt horizon(#)} specifies the forecast horizon (number of steps ahead). Required.
Requires a prior {cmd:qvar estimate}.

{phang}
{opt nsims(#)} specifies the number of Monte Carlo simulation paths.
Default is {cmd:10000}.

{phang}
{opt seed(#)} sets the random number seed for reproducibility. Default is {cmd:42}.

{phang}
{opt stress(string)} specifies a stress-testing scenario.

{phang}
{opt variable(string)} specifies the variable to focus the stress test on.

{dlgtab:irf options}

{phang}
{opt shockvar(varname)} specifies the variable receiving the impulse shock. Required.
Requires a prior {cmd:qvar estimate}.

{phang}
{opt shocksize(#)} specifies the magnitude of the shock in standard-deviation
units. Default is {cmd:1.0}.

{phang}
{opt horizon(#)} specifies the IRF horizon. Default is {cmd:20}.

{phang}
{opt taupath(numlist)} specifies the quantile path for the IRF computation.
Default is {cmd:0.50} (median).

{phang}
{opt nboot(#)} specifies the number of bootstrap replications for
confidence bands. Default is {cmd:500}.

{phang}
{opt seed(#)} sets the random number seed. Default is {cmd:42}.

{phang}
{opt compare(numlist)} requests a comparison of IRFs across the specified
quantile paths.

{dlgtab:evaluate options}

{phang}
{opt actual(varname)} specifies the variable containing realized values. Required.

{phang}
{opt taus(numlist)} specifies the quantile levels corresponding to each
forecast variable in {varlist}. Default is {cmd:0.05 0.25 0.50 0.75 0.95}.

{phang}
{opt weight(string)} specifies the weight function for qwCRPS:
{cmd:tails} (default), {cmd:left}, {cmd:right}, or {cmd:uniform}.

{phang}
{opt horizon(#)} specifies the forecast horizon for Diebold-Mariano HAC
variance. Default is {cmd:1}.

{phang}
{opt nominal(#)} specifies the nominal coverage probability for the
Christoffersen (1998) coverage test. Default is {cmd:0.90}.


{marker subcommands}{...}
{title:Subcommands}

{dlgtab:plot}

{pstd}
{bf:qvar plot} {it:plottype} [{cmd:,} {it:options}]

{pstd}
where {it:plottype} is one of

{p2colset 9 28 30 2}{...}
{p2col:{opt coef}}coefficient bubble heatmap across quantiles{p_end}
{p2col:{opt cusum}}CUSUM process with optional breakpoint{p_end}
{p2col:{opt regime}}Granger causality regime timeline bar{p_end}
{p2col:{opt fan}}forecast fan chart with nested confidence bands{p_end}
{p2col:{opt irf}}single-quantile IRF with confidence bands{p_end}
{p2col:{opt irfcompare}}multi-quantile IRF comparison overlay{p_end}
{p2col:{opt gar}}Growth-at-Risk time series plot{p_end}
{p2colreset}{...}

{pstd}
All plot types accept {opt saving(filename)} to export as PNG. The color
palette uses Teal (#0A6C74), Coral (#E8714A), Gold (#F4B942), Slate
(#4A5568), Lavender (#8B7EC8), Mint (#2ECC9B), and Rose (#E85D75).

{dlgtab:table}

{pstd}
{bf:qvar table} {it:tabletype} [{cmd:,} {it:options}]

{pstd}
where {it:tabletype} is one of

{p2colset 9 28 30 2}{...}
{p2col:{opt summary}}QVAR model summary (after {cmd:estimate}){p_end}
{p2col:{opt coef}}coefficient table across quantiles with significance stars{p_end}
{p2col:{opt granger}}Granger causality test results (after {cmd:granger}){p_end}
{p2col:{opt eval}}forecast evaluation results (after {cmd:evaluate}){p_end}
{p2colreset}{...}

{pstd}
Table options include {opt fmt(string)} for output format ({cmd:console},
{cmd:latex}, or {cmd:html}), {opt taus(numlist)} for coefficient tables,
and {opt saving(filename)} for file output.


{marker description}{...}
{title:Description}

{pstd}
{cmd:qvar} implements Quantile Vector Autoregression models for Stata,
providing a comprehensive toolkit for quantile-based multivariate
time-series analysis. The package supports the complete QVAR workflow:
estimation, testing, forecasting, impulse responses, evaluation, and
publication-quality visualization.

{pstd}
{bf:Key features:}

{p 8 12 2}
{bf:1. QVAR estimation} ({cmd:qvar estimate}): Equation-by-equation quantile
regression with optional recursive (lower-triangular) contemporaneous structure
following Chavleishvili & Manganelli (2019). Estimates conditional quantile
functions Q_{y_k}(tau | x) for each variable and quantile level.

{p 8 12 2}
{bf:2. Quantile Granger causality} ({cmd:qvar granger}): Tests the joint null
of no Granger causality and constant parameters using supLM and expLM
statistics with bootstrap p-values (Algorithm 1 of Mayer, Wied & Troster,
2025). Includes sequential regime detection (Algorithm 2) and the supWald
comparison test of Koenker & Machado (1999).

{p 8 12 2}
{bf:3. VAR-QR model} ({cmd:qvar varqr}): Two-stage Growth-at-Risk estimation
following Carboni et al. (2024). Stage 1 fits an OLS VAR for the conditional
mean; Stage 2 applies quantile regression to VAR residuals to extract
time-varying conditional volatility.

{p 8 12 2}
{bf:4. Quantile forecasting} ({cmd:qvar forecast}): Multi-step ahead density
forecasting via Monte Carlo simulation using the random coefficient
representation of Surprenant (2025). Computes Expected Shortfall (ES) and
Expected Longrise (EL) risk measures.

{p 8 12 2}
{bf:5. Quantile IRF} ({cmd:qvar irf}): Quantile impulse response functions
following White, Kim & Manganelli (2015) and Chavleishvili & Manganelli (2019).
Computes point IRFs via coefficient propagation with bootstrap confidence bands.
Supports multi-quantile comparison.

{p 8 12 2}
{bf:6. Forecast evaluation} ({cmd:qvar evaluate}): Quantile-weighted CRPS
(Gneiting & Ranjan, 2011), Diebold-Mariano (1995) pairwise comparison with
HAC standard errors, and Christoffersen (1998) unconditional coverage test.

{pstd}
The data must be {cmd:tsset} before using {cmd:qvar}. Panel data is not
currently supported.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup}

        {cmd:. webuse lutkepohl2, clear}
        {cmd:. tsset qtr}

{pstd}
{bf:1. QVAR estimation with recursive structure}

        {cmd:. qvar estimate dln_inv dln_inc dln_consump, lags(1) taus(0.10 0.50 0.90) recursive}

{pstd}
{bf:2. View estimation results}

        {cmd:. ereturn list}
        {cmd:. matrix list _qvar_b_0_50_eq1}

{pstd}
{bf:3. Summary and coefficient tables}

        {cmd:. qvar table summary}
        {cmd:. qvar table coef, taus(0.10 0.50 0.90)}
        {cmd:. qvar table coef, taus(0.10 0.50 0.90) fmt(latex)}

{pstd}
{bf:4. Quantile Granger causality: income -> investment}

        {cmd:. qvar granger dln_inv dln_inc, lags(1) bootstrap(499) regimes}
        {cmd:. qvar table granger}

{pstd}
{bf:5. VAR-QR Growth-at-Risk model}

        {cmd:. qvar varqr dln_inv dln_inc dln_consump, varlags(2) taus(0.10 0.90)}

{pstd}
{bf:6. Quantile IRF: shock to income}

        {cmd:. qvar estimate dln_inv dln_inc, lags(1) taus(0.05 0.50 0.95)}
        {cmd:. qvar irf, shockvar(dln_inc) horizon(20) shocksize(1) taupath(0.50)}

{pstd}
{bf:7. Multi-step forecasting}

        {cmd:. qvar estimate dln_inv dln_inc, lags(1) taus(0.05 0.25 0.50 0.75 0.95)}
        {cmd:. qvar forecast, horizon(12) nsims(5000) seed(42)}

{pstd}
{bf:8. Forecast evaluation}

        {cmd:. qvar evaluate fc_q05 fc_q50 fc_q95, actual(dln_inv) taus(0.05 0.50 0.95) weight(tails)}

{pstd}
{bf:9. Stationarity check (utility)}

        {cmd:. _qvar_stationarity_check dln_inv dln_inc dln_consump}

{pstd}
{bf:10. Publication-quality plots}

        {cmd:. qvar plot coef, equation(dln_inv) taus(0.10 0.50 0.90) saving(coef_heatmap.png)}
        {cmd:. qvar plot irf, irf(_qvar_irf_dln_inc_dln_inv) lower(_qvar_irf_lo_dln_inc_dln_inv) upper(_qvar_irf_hi_dln_inc_dln_inv)}


{marker results}{...}
{title:Stored results}

{pstd}
{bf:qvar estimate} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(n_vars)}}number of endogenous variables{p_end}
{synopt:{cmd:e(n_lags)}}number of lags{p_end}
{synopt:{cmd:e(n_obs)}}number of usable observations{p_end}
{synopt:{cmd:e(n_taus)}}number of quantile levels{p_end}
{synopt:{cmd:e(recursive)}}1 if recursive structure used, 0 otherwise{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qvar estimate}{p_end}
{synopt:{cmd:e(varnames)}}list of endogenous variable names{p_end}
{synopt:{cmd:e(taus)}}list of quantile levels{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:_qvar_b_}{it:tau}{cmd:_eq}{it:#}}coefficient vector for quantile {it:tau}, equation {it:#}{p_end}
{synopt:{cmd:_qvar_se_}{it:tau}{cmd:_eq}{it:#}}standard error vector{p_end}

{p2col 5 25 29 2: Variables}{p_end}
{synopt:{cmd:_qvar_resid_t}{it:tau}{cmd:_}{it:var}}quantile regression residuals{p_end}

{pstd}
{bf:qvar granger} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(n_obs)}}number of observations{p_end}
{synopt:{cmd:e(n_gc_lags)}}number of GC lags{p_end}
{synopt:{cmd:e(n_bootstrap)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(sup_lm)}}supLM test statistic{p_end}
{synopt:{cmd:e(sup_lm_pval)}}bootstrap p-value for supLM{p_end}
{synopt:{cmd:e(exp_lm)}}expLM test statistic{p_end}
{synopt:{cmd:e(exp_lm_pval)}}bootstrap p-value for expLM{p_end}
{synopt:{cmd:e(sup_wald)}}supWald statistic (if computed){p_end}
{synopt:{cmd:e(sup_wald_pval)}}simulation p-value for supWald{p_end}
{synopt:{cmd:e(n_regimes)}}number of detected regimes (1 or 2){p_end}
{synopt:{cmd:e(breakpoint)}}breakpoint fraction (if 2 regimes){p_end}
{synopt:{cmd:e(bp_obs)}}breakpoint observation number{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qvar granger}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(gcvar)}}Granger-causing variable{p_end}
{synopt:{cmd:e(controls)}}control variables{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(wald_stats)}}Wald statistics across quantile grid{p_end}

{pstd}
{bf:qvar varqr} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{synopt:{cmd:e(cmd)}}{cmd:qvar varqr}{p_end}
{synopt:{cmd:e(varnames)}}variable names{p_end}
{synopt:{cmd:e(n_vars)}}number of variables{p_end}
{synopt:{cmd:e(var_lags)}}number of VAR lags{p_end}
{synopt:{cmd:e(qr_lags)}}number of QR lags{p_end}
{synopt:{cmd:e(n_obs)}}number of observations{p_end}
{synopt:{cmd:e(var_aic)}}VAR AIC{p_end}

{p2col 5 25 29 2: Variables}{p_end}
{synopt:{cmd:_varqr_resid_}{it:var}}VAR residuals for each variable{p_end}
{synopt:{cmd:_varqr_sigma_}{it:var}}estimated time-varying volatility{p_end}

{pstd}
{bf:qvar irf} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{synopt:{cmd:e(irf_horizon)}}IRF horizon{p_end}
{synopt:{cmd:e(irf_shocksize)}}shock magnitude{p_end}
{synopt:{cmd:e(irf_shockvar)}}shock variable name{p_end}
{synopt:{cmd:e(irf_taupath)}}quantile path used{p_end}

{p2col 5 25 29 2: Variables}{p_end}
{synopt:{cmd:_qvar_irf_}{it:shock}{cmd:_}{it:resp}}point IRF{p_end}
{synopt:{cmd:_qvar_irf_lo_}{it:shock}{cmd:_}{it:resp}}lower 68% confidence band{p_end}
{synopt:{cmd:_qvar_irf_hi_}{it:shock}{cmd:_}{it:resp}}upper 68% confidence band{p_end}

{pstd}
{bf:qvar forecast} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{synopt:{cmd:e(fc_horizon)}}forecast horizon{p_end}
{synopt:{cmd:e(fc_nsims)}}number of simulations{p_end}
{synopt:{cmd:e(fc_seed)}}random seed used{p_end}

{pstd}
{bf:qvar evaluate} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{synopt:{cmd:r(qw_crps)}}quantile-weighted CRPS{p_end}
{synopt:{cmd:r(dm_stat)}}Diebold-Mariano test statistic{p_end}
{synopt:{cmd:r(dm_pval)}}Diebold-Mariano p-value{p_end}
{synopt:{cmd:r(dm_diff)}}mean loss differential{p_end}
{synopt:{cmd:r(coverage)}}empirical coverage probability{p_end}
{synopt:{cmd:r(uc_stat)}}unconditional coverage LR statistic{p_end}
{synopt:{cmd:r(uc_pval)}}unconditional coverage p-value{p_end}


{marker references}{...}
{title:References}

{phang}
Carboni, G., Fonseca, L., Fornari, F. and Urrutia, A. (2024). Structural
Drivers of Growth-at-Risk. {it:ECB Working Paper} 3171.

{phang}
Chavleishvili, S. and Manganelli, S. (2019). Forecasting and Stress Testing
with Quantile Vector Autoregression. {it:ECB Working Paper} 2330.

{phang}
Christoffersen, P. (1998). Evaluating Interval Forecasts.
{it:International Economic Review}, 39(4), 841-862.

{phang}
Diebold, F.X. and Mariano, R.S. (1995). Comparing Predictive Accuracy.
{it:Journal of Business & Economic Statistics}, 13(3), 253-263.

{phang}
Gneiting, T. and Ranjan, R. (2011). Comparing Density Forecasts Using
Threshold- and Quantile-Weighted Scoring Rules.
{it:Journal of Business & Economic Statistics}, 29(3), 411-422.

{phang}
Koenker, R. and Machado, J.A.F. (1999). Goodness of Fit and Related
Inference Processes for Quantile Regression.
{it:Journal of the American Statistical Association}, 94(448), 1296-1310.

{phang}
Mayer, A., Wied, D. and Troster, B. (2025). Quantile Granger Causality in
the Presence of Instability. {it:Journal of Econometrics}, 249.

{phang}
Surprenant, S. (2025). Quantile VARs and Macroeconomic Risk Forecasting.
{it:Bank of Canada Staff Working Paper} 2025-4.

{phang}
White, H., Kim, T.-H. and Manganelli, S. (2015). VAR for VaR: Measuring
Tail Dependence Using Multivariate Regression Quantiles.
{it:Journal of Econometrics}, 187(1), 169-188.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane/QVAR"}


{title:Also see}

{psee}
{space 2}Help:  {helpb qreg}, {helpb var}, {helpb dfuller}, {helpb bsample}
{p_end}
