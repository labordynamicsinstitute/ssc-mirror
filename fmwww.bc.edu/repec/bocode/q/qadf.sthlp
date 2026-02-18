{smcl}
{* *! version 1.0.0  February 2026}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] pperron" "help pperron"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{viewerjumpto "Syntax" "qadf##syntax"}{...}
{viewerjumpto "Description" "qadf##description"}{...}
{viewerjumpto "Options" "qadf##options"}{...}
{viewerjumpto "Interpreting results" "qadf##interpretation"}{...}
{viewerjumpto "Examples" "qadf##examples"}{...}
{viewerjumpto "Stored results" "qadf##results"}{...}
{viewerjumpto "Methods and formulas" "qadf##methods"}{...}
{viewerjumpto "References" "qadf##references"}{...}
{viewerjumpto "Author" "qadf##author"}{...}

{title:Title}

{phang}
{bf:qadf} {hline 2} Quantile Autoregression Unit Root Test (Koenker & Xiao, 2004)


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Single-quantile test}

{p 8 17 2}
{cmd:qadf}
{varname}
{ifin}
[{cmd:,} {it:qadf_options}]

{pstd}
{bf:Multi-quantile process}

{p 8 17 2}
{cmd:qadf_process}
{varname}
{ifin}
[{cmd:,} {it:process_options}]

{pstd}
{bf:Bootstrap inference}

{p 8 17 2}
{cmd:qadf_boot}
{varname}
{ifin}
[{cmd:,} {it:boot_options}]

{pstd}
{bf:Visualization}

{p 8 17 2}
{cmd:qadf_graph}
[{cmd:,} {it:graph_options}]


{dlgtab:qadf options}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt tau(#)}}quantile; default is {cmd:tau(0.5)}{p_end}
{synopt:{opt m:odel(string)}}model specification; {cmd:c} (constant, default) or {cmd:ct} (constant + trend){p_end}
{synopt:{opt maxl:ags(#)}}maximum ADF lags; default is {cmd:maxlags(8)}{p_end}
{synopt:{opt ic(string)}}information criterion; {cmd:aic} (default), {cmd:bic}, or {cmd:tstat}{p_end}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt nopr:int}}suppress output display{p_end}
{synoptline}

{dlgtab:qadf_process options}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt q:uantiles(numlist)}}quantiles to evaluate; default is {cmd:quantiles(0.1 0.2 ... 0.9)}{p_end}
{synopt:{opt m:odel(string)}}model specification{p_end}
{synopt:{opt maxl:ags(#)}}maximum ADF lags{p_end}
{synopt:{opt ic(string)}}information criterion{p_end}
{synopt:{opt boot:strap}}use bootstrap for QKS/QCM critical values{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default is {cmd:reps(399)}{p_end}
{synopt:{opt seed(#)}}random seed for reproducibility{p_end}
{synoptline}

{dlgtab:qadf_boot options}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt tau(#)}}quantile{p_end}
{synopt:{opt m:odel(string)}}model specification{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default is {cmd:reps(399)}{p_end}
{synopt:{opt seed(#)}}random seed{p_end}
{synoptline}

{dlgtab:qadf_graph options}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sav:ing(filename)}}save graph to file{p_end}
{synopt:{opt sch:eme(scheme)}}graph scheme; default is {cmd:scheme(s2color)}{p_end}
{synopt:{opt t:itle(string)}}custom title{p_end}
{synopt:{opt com:bine}}combined 4-panel plot (default){p_end}
{synopt:{opt rhoonly}}coefficient plot only{p_end}
{synopt:{opt tstatonly}}t-statistic plot only{p_end}
{synopt:{opt delta2only}}delta-squared plot only{p_end}
{synopt:{opt halflifeonly}}half-life plot only{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:qadf}; see {helpb tsset:[TS] tsset}.{p_end}
{p 4 6 2}
{it:varname} may contain time-series operators; see {help tsvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:qadf} performs the Quantile Autoregression (QAR) unit root test proposed by
Koenker and Xiao (2004). This test provides a more robust approach to testing
the unit root hypothesis compared to conventional ADF and Phillips-Perron tests,
especially for data with non-Gaussian disturbances (heavy-tailed distributions).

{pstd}
{bf:Key features:}

{phang2}1. {bf:Robustness:} Superior power under non-Gaussian conditions
(heavy-tailed distributions) compared to standard unit root tests.{p_end}

{phang2}2. {bf:Asymmetric dynamics:} The quantile approach reveals how persistence
varies across quantiles, capturing asymmetric adjustment behavior. For example,
a series might be mean-reverting after negative shocks (low quantiles) but
explosive after positive shocks (high quantiles).{p_end}

{phang2}3. {bf:Multiple test procedures:} Individual quantile tests t_n(tau),
coefficient-based tests U_n(tau), and global Kolmogorov-Smirnov (QKS) and
Cramer-von Mises (QCM) tests across all quantiles.{p_end}

{phang2}4. {bf:Flexible inference:} Hansen (1995) tabulated critical values
(indexed by delta-squared) and optional bootstrap critical values.{p_end}

{pstd}
The commands are organized as follows:

{phang2}{cmd:qadf} performs the test at a single quantile.{p_end}
{phang2}{cmd:qadf_process} performs the test across multiple quantiles and
computes global QKS and QCM statistics.{p_end}
{phang2}{cmd:qadf_boot} computes bootstrap p-values and critical values.{p_end}
{phang2}{cmd:qadf_graph} creates publication-quality plots from {cmd:qadf_process}
results.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt tau(#)} specifies the quantile at which to perform the QAR unit root
test. The value must be strictly between 0 and 1. Common choices include
0.5 (median), 0.25, and 0.75. The default is {cmd:tau(0.5)}.

{phang}
{opt model(string)} specifies the deterministic component in the QAR model:

{phang2}{cmd:c} (the default) includes a constant (intercept) only:{break}
Q_{y_t}(tau|F_{t-1}) = alpha_0(tau) + alpha_1 * y_{t-1} + sum[alpha_{j+1} * dy_{t-j}] + u_t{p_end}

{phang2}{cmd:ct} includes both a constant and a linear time trend:{break}
Q_{y_t}(tau|F_{t-1}) = alpha_0(tau) + alpha_1 * y_{t-1} + beta * t + sum[alpha_{j+1} * dy_{t-j}] + u_t{p_end}

{phang}
{opt maxlags(#)} specifies the maximum number of lagged first differences
to include in the ADF regression. The optimal lag is selected according
to the chosen information criterion. The default is {cmd:maxlags(8)}.

{phang}
{opt ic(string)} specifies the lag selection method:

{phang2}{cmd:aic} (the default) uses the Akaike Information Criterion.{p_end}
{phang2}{cmd:bic} uses the Bayesian (Schwarz) Information Criterion.{p_end}
{phang2}{cmd:tstat} uses the t-statistic significance rule: starts at the
maximum lag and reduces until the last lag coefficient is significant at 5%.{p_end}

{dlgtab:Bootstrap}

{phang}
{opt bootstrap} (in {cmd:qadf_process}) requests that bootstrap critical
values be computed for the QKS and QCM global statistics. This follows
the resampling procedure in Section 3.2 of Koenker and Xiao (2004).

{phang}
{opt reps(#)} specifies the number of bootstrap replications. The default
is {cmd:reps(399)}. Higher values produce more precise p-values but
require more computation time.

{phang}
{opt seed(#)} sets the random number seed for reproducibility.


{marker interpretation}{...}
{title:Interpreting results}

{dlgtab:Single-quantile output (qadf)}

{phang}
{bf:rho_1(tau) [QR]:} The quantile autoregressive coefficient at quantile tau.
If rho_1(tau) < 1 the series is mean-reverting at that quantile; 
if rho_1(tau) >= 1 it behaves like a unit root or is explosive.{p_end}

{phang}
{bf:rho_1 [OLS]:} The standard OLS estimate of the autoregressive coefficient.
This is the conventional ADF estimate and does not vary across quantiles.{p_end}

{phang}
{bf:alpha_0(tau):} The quantile-specific intercept. This captures the
location shift of the conditional distribution at each quantile.{p_end}

{phang}
{bf:delta-sq:} The estimated nuisance parameter delta^2, which measures the
long-run correlation between the first differences and quantile indicator.
It indexes the critical values from Hansen (1995). Values near 0 yield
critical values close to the standard normal; values near 1 yield critical
values close to the Dickey-Fuller distribution.{p_end}

{phang}
{bf:Half-life:} The number of periods needed for a shock to decay by 50%,
computed as ln(0.5)/ln(rho_1(tau)). Only meaningful when rho_1(tau) < 1
(stationary quantile). Displayed as "---" when rho_1(tau) >= 1.{p_end}

{phang}
{bf:t_n(tau):} The quantile unit root t-statistic (Equation 9 in the paper).
This is a {bf:left-tail test}. Reject H0 (unit root) when t_n(tau) is
sufficiently negative (i.e., below the critical value).{p_end}

{phang}
{bf:U_n(tau) = n(rho-1):} The coefficient-based test statistic. Large negative
values indicate stationarity. This is analogous to the Dickey-Fuller 
normalized bias statistic.{p_end}

{phang}
{bf:Critical values:} From Hansen (1995), indexed by delta-sq. The test is
one-sided (left-tail):
{break}    - Reject H0 at 1% if t_n(tau) < CV(1%)
{break}    - Reject H0 at 5% if t_n(tau) < CV(5%)
{break}    - Reject H0 at 10% if t_n(tau) < CV(10%)
{break}Significance levels are marked as *** (1%), ** (5%), * (10%).{p_end}

{dlgtab:Multi-quantile output (qadf_process)}

{phang}
{bf:The process table} reports rho_1(tau), t_n(tau), U_n(tau), delta-sq, and
critical values at 1%, 5%, and 10% for each quantile. This allows you to
see how persistence varies across the conditional distribution.{p_end}

{phang}
{bf:Typical interpretation patterns:}{p_end}

{phang2}(a) {bf:Unit root at all quantiles:} rho_1(tau) near 1 everywhere, no
rejections. The series has a unit root across the entire distribution.{p_end}

{phang2}(b) {bf:Stationary at all quantiles:} rho_1(tau) < 1 everywhere, with
significant t_n(tau) at most quantiles. The series is globally stationary.{p_end}

{phang2}(c) {bf:Asymmetric persistence:} rho_1(tau) < 1 at some quantiles but
>= 1 at others. For example, stationary at low quantiles (negative shocks
die out) but explosive at high quantiles (positive shocks persist). This is
the key advantage of the QADF test over standard ADF.{p_end}

{dlgtab:Global statistics (QKS and QCM)}

{phang}
{bf:QKS (Kolmogorov-Smirnov type):} Tests whether the coefficient equals 1
at {it:any} quantile. QKS = sup|t_n(tau)|. Reject if QKS exceeds the
bootstrap critical value (right-tail test). Sensitive to deviations at
individual quantiles.{p_end}

{phang}
{bf:QCM (Cramer-von Mises type):} Tests whether the coefficient equals 1
across {it:all} quantiles on average. QCM = int t_n(tau)^2 dtau. Reject if
QCM exceeds the bootstrap critical value (right-tail test). More powerful
when deviations from unity are spread across many quantiles.{p_end}

{phang}
{bf:Note:} QKS and QCM have non-standard distributions. Use the {cmd:bootstrap}
option in {cmd:qadf_process} to obtain data-specific critical values for
these statistics.{p_end}

{dlgtab:Bootstrap output (qadf_boot)}

{phang}
{bf:Bootstrap p-value:} The proportion of bootstrap t-statistics that are
more extreme (more negative) than the observed t_n(tau). A small p-value
(< 0.05) indicates rejection of the unit root null, providing finite-sample
inference that does not rely on asymptotic critical values.{p_end}

{phang}
{bf:Bootstrap critical values:} Data-specific critical values at 1%, 5%,
and 10% significance levels, obtained from the empirical distribution of
bootstrap t-statistics under H0 (unit root).{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Basic QADF test at median{p_end}
{phang2}{cmd:. qadf inv, tau(0.5)}{p_end}

{pstd}QADF test at lower quartile with trend{p_end}
{phang2}{cmd:. qadf inv, tau(0.25) model(ct)}{p_end}

{pstd}Multi-quantile process (9 quantiles, default){p_end}
{phang2}{cmd:. qadf_process inv}{p_end}

{pstd}Multi-quantile process with bootstrap QKS/QCM critical values{p_end}
{phang2}{cmd:. qadf_process inv, bootstrap reps(499) seed(12345)}{p_end}

{pstd}Custom quantiles and BIC lag selection{p_end}
{phang2}{cmd:. qadf_process inv, quantiles(0.1 0.25 0.5 0.75 0.9) ic(bic)}{p_end}

{pstd}Bootstrap inference at a single quantile{p_end}
{phang2}{cmd:. qadf_boot inv, tau(0.5) reps(999) seed(42)}{p_end}

{pstd}Visualization (after qadf_process){p_end}
{phang2}{cmd:. qadf_process inv}{p_end}
{phang2}{cmd:. qadf_graph}{p_end}

{pstd}Save graph to file{p_end}
{phang2}{cmd:. qadf_graph, saving(qadf_results.png)}{p_end}

{pstd}Individual coefficient plot only{p_end}
{phang2}{cmd:. qadf_graph, rhoonly}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:qadf} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(tau)}}quantile{p_end}
{synopt:{cmd:r(lags)}}optimal lag length{p_end}
{synopt:{cmd:r(qadf)}}QADF t-statistic t_n(tau){p_end}
{synopt:{cmd:r(Unstat)}}coefficient statistic U_n(tau) = n(alpha_1 - 1){p_end}
{synopt:{cmd:r(rho_tau)}}QR estimate of alpha_1(tau){p_end}
{synopt:{cmd:r(rho_ols)}}OLS estimate of alpha_1{p_end}
{synopt:{cmd:r(alpha_tau)}}QR estimate of alpha_0(tau){p_end}
{synopt:{cmd:r(delta2)}}estimated delta-squared{p_end}
{synopt:{cmd:r(half_life)}}shock half-life{p_end}
{synopt:{cmd:r(cv1)}}1% critical value (Hansen 1995){p_end}
{synopt:{cmd:r(cv5)}}5% critical value (Hansen 1995){p_end}
{synopt:{cmd:r(cv10)}}10% critical value (Hansen 1995){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of variable{p_end}
{synopt:{cmd:r(model)}}model specification{p_end}
{synopt:{cmd:r(ic)}}information criterion{p_end}
{synopt:{cmd:r(cmd)}}{cmd:qadf}{p_end}

{pstd}
{cmd:qadf_process} additionally stores:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(QKS_alpha)}}QKS statistic based on U_n{p_end}
{synopt:{cmd:r(QKS_t)}}QKS statistic based on t_n{p_end}
{synopt:{cmd:r(QCM_alpha)}}QCM statistic based on U_n{p_end}
{synopt:{cmd:r(QCM_t)}}QCM statistic based on t_n{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}matrix of results (tau, rho, tstat, Ustat, delta2, cv1, cv5, cv10, halflife){p_end}

{pstd}
{cmd:qadf_boot} additionally stores:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(boot_pvalue)}}bootstrap p-value{p_end}
{synopt:{cmd:r(boot_cv1_t)}}1% bootstrap CV for t_n{p_end}
{synopt:{cmd:r(boot_cv5_t)}}5% bootstrap CV for t_n{p_end}
{synopt:{cmd:r(boot_cv10_t)}}10% bootstrap CV for t_n{p_end}
{synopt:{cmd:r(boot_nvalid)}}valid bootstrap replications{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
Consider the pth-order quantile autoregression model (equation 7 of the paper):

{p 8 8 2}
Q_{y_t}(tau | F_{t-1}) = alpha_0(tau) + alpha_1 * y_{t-1} + sum_{j=1}^{q} alpha_{j+1} * dy_{t-j}

{pstd}
where alpha_0(tau) = Q_u(tau) is the tau-th quantile of the innovation, and alpha_1 is
the autoregressive coefficient. Under H0: alpha_1 = 1, y_t contains a unit root.

{pstd}
{bf:t-statistic (equation 9):}

{p 8 8 2}
t_n(tau) = [f_hat(F^{-1}(tau)) / sqrt(tau(1-tau))] * sqrt(Y'_{-1} * PX * Y_{-1}) * (alpha_1_hat(tau) - 1)

{pstd}
where f_hat is the estimated quantile density function, Y_{-1} is the vector of
lagged levels, and PX is the projection matrix onto the space orthogonal to
X = (1, dy_{t-1}, ..., dy_{t-q}).

{pstd}
{bf:Limiting distribution (equation 10):}

{p 8 8 2}
t_n(tau) => delta * DF + sqrt(1 - delta^2) * N(0,1)

{pstd}
where DF = [int W1^2]^{-1/2} * int W1 dW1 is the Dickey-Fuller distribution,
and delta = sigma_{w,psi}(tau) / (sigma_w * sqrt(tau(1-tau))) is the long-run
correlation between the first differences w_t = dy_t and psi_tau(u_{t,tau}).

{pstd}
{bf:Delta-squared estimation:} The nuisance parameter delta^2 is estimated as
delta_hat^2 = Cov(w, phi)^2 / (Var(w) * tau * (1-tau)), where phi_t = tau - I(u_hat_t < 0).
This follows the GAUSS implementation approach.

{pstd}
{bf:Critical values:} Critical values for the test are taken from Hansen (1995,
Table II) and are indexed by delta^2. Linear interpolation is used between
tabulated values.

{pstd}
{bf:Global statistics (equations 13-14):}

{p 8 8 2}
QKS_t = sup_{tau in T} |t_n(tau)|,  QCM_t = int_{tau in T} t_n(tau)^2 dtau

{pstd}
{bf:Bootstrap procedure (Section 3.2):}

{phang}Step 1: Fit AR(q) to w_t = dy_t by OLS.{p_end}
{phang}Step 2: Draw iid {u*_t} from centered residuals.{p_end}
{phang}Step 3: Generate y*_t = y*_{t-1} + w*_t under H0 (unit root).{p_end}
{phang}Step 4: Estimate QAR regression on bootstrap sample.{p_end}


{marker references}{...}
{title:References}

{phang}
Bofinger, E. 1975. Estimation of a density function using order statistics.
{it:Australian Journal of Statistics} 17: 1-7.

{phang}
Hall, P., and S.J. Sheather. 1988. On the distribution of a studentized
quantile. {it:JRSS-B} 50(3): 381-391.

{phang}
Hansen, B. 1995. Rethinking the univariate approach to unit root tests: How
to use covariates to increase power. {it:Econometric Theory} 11: 1148-1171.

{phang}
Koenker, R., and G. Bassett. 1978. Regression quantiles.
{it:Econometrica} 46: 33-49.

{phang}
Koenker, R., and Z. Xiao. 2004. Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99: 775-787.

{phang}
Siddiqui, M. 1960. Distribution of quantiles from a bivariate population.
{it:Journal of Research of the National Bureau of Standards} 64B: 145-150.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{break}
GitHub: {browse "https://github.com/merwanroudane/quantileadf"}

{pstd}
Please cite as:{break}
Roudane, M. 2026. QADF: Stata module to perform Quantile ADF unit root tests.

{pstd}
This implementation is based on the methodology in Koenker and Xiao (2004)
and the GAUSS code by Saban Nazlioglu (TSPDLIB package).


{title:Also see}

{psee}
Manual:  {manlink TS dfuller}, {manlink TS pperron}

{psee}
{space 2}Help:  {help dfuller}, {help pperron}, {help dfgls}, {help kpss} (if installed),
{help punit} (if installed)
{p_end}
