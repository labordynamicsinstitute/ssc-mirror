{smcl}
{* 03mar2026}{...}
{cmd:help xtrec} {right:version 1.0.0}
{hline}
{title:Title}

{p 4 4}{cmd:xtrec} — Panel unit root test based on recursive detrending (Westerlund 2015).

{title:Version}

{pstd}
Version 1.0.0, 3 March 2026

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{title:Syntax}

{p 4 13}{cmd:xtrec} {it:varname} [{cmd:if}] [{cmd:in}], [{cmd:trend(}{it:{help integer}}{cmd:)}
{cmdab:maxl:ag(}{it:{help integer}}{cmd:)}
{cmdab:rob:ust}
{cmdab:nogr:aph}
{cmdab:nota:ble}
{cmd:level(}{it:{help integer}}{cmd:)}]{p_end}

{p 4 4}{it:varname} is the panel variable to test for a unit root.{break}
Data must be {cmd:xtset} before using {cmd:xtrec}; see {help xtset}.{p_end}

{p 4 4}The panel must be {ul:strongly balanced}. The data are automatically first-differenced
and recursively detrended within the command.{p_end}

{title:Contents}

{p 4}{help xtrec##description:Description}{p_end}
{p 4}{help xtrec##econmodel:Econometric Model}{p_end}
{p 4}{help xtrec##methodology:Methodology}{p_end}
{p 4}{help xtrec##options:Options}{p_end}
{p 4}{help xtrec##table1:Table 1: Asymptotic Coefficients}{p_end}
{p 4}{help xtrec##power:Power Properties}{p_end}
{p 4}{help xtrec##interpretation:Interpretation Guide}{p_end}
{p 4}{help xtrec##graphs:Diagnostics and Graphs}{p_end}
{p 4}{help xtrec##saved:Saved Values}{p_end}
{p 4}{help xtrec##examples:Examples}{p_end}
{p 4}{help xtrec##references:References}{p_end}
{p 4}{help xtrec##citation:Citation}{p_end}
{p 4}{help xtrec##also:Also see}{p_end}
{p 4}{help xtrec##about:About}{p_end}

{marker description}{title:Description}

{p 4 4}{cmd:xtrec} performs a panel unit root test based on recursively detrended
data as proposed by Westerlund (2015, Journal of Econometrics). Two test statistics
are available:{p_end}

{p 8 12 2}{bf:t-REC}: the baseline test assuming iid errors. Asymptotically
distributed as N(0,1) under the null hypothesis of a unit root, {it:regardless}
of the degree of the fitted trend polynomial. This invariance property is unique
among all panel unit root tests and eliminates the need for any mean or variance
correction factors.{p_end}

{p 8 12 2}{bf:t-RREC}: the robust version (invoked with the {opt robust} option)
that accommodates serial correlation, cross-section dependence (via a common factor
structure), and cross-section heteroskedasticity. Its null distribution is also
N(0,1), and the invariance property extends to general trend functions beyond
polynomials (including smooth transition shifts and trigonometric functions).{p_end}

{p 4 4}{bf:Key advantages over existing panel unit root tests:}{p_end}
{p 8 12 2}{c -} The null distribution is invariant to both the true and fitted trend degree.{p_end}
{p 8 12 2}{c -} No mean/variance correction factors are needed (unlike IPS, LLC, etc.).{p_end}
{p 8 12 2}{c -} Critical values are simply from the standard Normal distribution.{p_end}
{p 8 12 2}{c -} Critical region is always the left tail (unlike Breitung's test where it varies).{p_end}
{p 8 12 2}{c -} Enables testing with higher-order polynomial trends (quadratic, cubic, etc.) which is not possible with existing tests.{p_end}
{p 8 12 2}{c -} For p < 1 (no trend terms), power lies within N^(-1/2)*T^(-1)-neighborhoods.{p_end}
{p 8 12 2}{c -} For p >= 1 (at least linear trend), power lies within N^(-1/4)*T^(-1)-neighborhoods.{p_end}

{marker econmodel}{title:Econometric Model}

{p 4 4}The data generating process is given by:{p_end}

{p 8 12} Y_it = beta_i' D_{t,p+1} + U_it {p_end}
{p 8 12} U_it = rho_i * U_{i,t-1} + epsilon_it {p_end}
{p 8 12} rho_i = exp(T^{-1} * alpha_N * c_i) {p_end}

{p 4 4}where:{p_end}
{p 8 12 2}D_{t,p+1} = (1, t, t^2, ..., t^p)' is a (p+1)-dimensional polynomial
trend vector.{p_end}
{p 8 12 2}alpha_N = N^{-kappa} governs the rate of shrinking of the local
alternative.{p_end}
{p 8 12 2}c_i is iid across panels with E(c_i) = mu_1 and E(c_i^2) = mu_2.{p_end}

{p 4 4}The null hypothesis is:{p_end}

{p 8 12} H0: c_1 = c_2 = ... = c_N = 0   (unit root for all panels) {p_end}

{p 4 4}against the double-sided alternative:{p_end}

{p 8 12} H1: c_i != 0 for at least some i   (some panels are stationary) {p_end}

{p 4 4}This is equivalently stated as H0: mu_2 = 0 versus H1: mu_2 > 0
(using the local parametrization).{p_end}

{p 4 4}{bf:Trend specification examples:}{p_end}
{p 8 12 2}{cmd:trend(0)}: Y_it = beta_0 + U_it (constant only){p_end}
{p 8 12 2}{cmd:trend(1)}: Y_it = beta_0 + beta_1*t + U_it (linear trend){p_end}
{p 8 12 2}{cmd:trend(2)}: Y_it = beta_0 + beta_1*t + beta_2*t^2 + U_it (quadratic trend){p_end}
{p 8 12 2}{cmd:trend(3)}: Y_it = beta_0 + beta_1*t + beta_2*t^2 + beta_3*t^3 + U_it (cubic trend){p_end}

{marker methodology}{title:Methodology}

{p 4 4}The {bf:t-REC} statistic is constructed in four steps:{p_end}

{p 8 12 2}{bf:Step 1} — First-difference: y_it = Delta Y_it. This is a restricted
(maximum likelihood) estimation under H0 and ensures the detrending regression is
not spurious.{p_end}

{p 8 12 2}{bf:Step 2} — Recursive detrending: For p >= 1, recursively detrend
y_it using only past and current observations to obtain y_{i,t,p}. This preserves
the martingale property of the data (unlike full-sample OLS detrending which
destroys it).{p_end}

{p 8 12 2}{bf:Step 3} — Accumulate: R_{i,t,p} = sum_{s=p+1}^t y_{i,s,p}. This is
an estimate of U_it under H0.{p_end}

{p 8 12 2}{bf:Step 4} — Compute the pooled t-ratio:{p_end}

{p 12 16}t-REC = A_{NT,p} / (sigma_hat * sqrt(B_{NT,p})){p_end}

{p 8 12 2}where:{p_end}
{p 12 16}A_{NT,p} = (1/(sqrt(N)*T)) * sum_i sum_t R_{i,t-1,p} * y_{i,t,p}{p_end}
{p 12 16}B_{NT,p} = (1/(N*T^2)) * sum_i sum_t R^2_{i,t-1,p}{p_end}
{p 12 16}sigma_hat^2 = (NT)^{-1} * sum_i sum_t y^2_{i,t,p}{p_end}

{p 4 4}The {bf:t-RREC} statistic additionally:{p_end}
{p 8 12 2}(a) Removes the common factor via cross-section averaging
(Pesaran 2007).{p_end}
{p 8 12 2}(b) Augments with BIC-selected lags for serial correlation.{p_end}
{p 8 12 2}(c) Scales by individual panel variance for heteroskedasticity.{p_end}

{p 12 16}t-RREC = [sum_i sum_t sigma^{-2}_{e,i} R_{i,t-1,p} r_{i,t,p}]
/ sqrt[sum_i sum_t sigma^{-2}_{e,i} R^2_{i,t-1,p}]{p_end}

{marker options}{title:Options}

{p 4 4}{cmd:trend(}{it:integer}{cmd:)} specifies the degree of the polynomial trend
to fit. The default is {cmd:trend(0)} (constant only, no trend). Set {cmd:trend(1)} for
a linear trend, {cmd:trend(2)} for quadratic, etc. The null distribution remains
N(0,1) regardless of this choice — no lookup tables or correction factors needed.{p_end}

{p 4 4}{cmdab:maxl:ag(}{it:integer}{cmd:)} sets the maximum lag augmentation order for
the robust t-RREC test. The default ({cmd:maxlag(-1)}) uses automatic BIC-based
selection with q_max = floor(4*(T/100)^(2/9)). Only relevant when {opt robust}
is specified.{p_end}

{p 4 4}{cmdab:rob:ust} computes the robust t-RREC statistic instead of t-REC. This
handles:{p_end}
{p 8 12 2}{c -} Serial correlation (via lag augmentation with BIC selection){p_end}
{p 8 12 2}{c -} Cross-section dependence (via cross-section averaging to remove common factor){p_end}
{p 8 12 2}{c -} Heteroskedasticity (via individual variance scaling){p_end}

{p 4 4}{cmdab:nogr:aph} suppresses the diagnostic graphs.{p_end}

{p 4 4}{cmdab:nota:ble} suppresses the output table.{p_end}

{p 4 4}{cmd:level(}{it:integer}{cmd:)} specifies the confidence level in percent.
Default is {cmd:level(95)}.{p_end}

{marker table1}{title:Table 1: Asymptotic Coefficients}

{p 4 4}From Westerlund (2015, Table 1), the coefficients a_p and b_p of the
asymptotic distribution are:{p_end}

{col 8}{hline 60}
{col 8}  p    {col 18}a_p       {col 32}b_p          {col 46}kappa  {col 58}Power by
{col 8}{hline 60}
{col 8}  -1   {col 18}0.50000   {col 32}0.33333      {col 46}1/2    {col 58}mu_1
{col 8}   0   {col 18}0.50000   {col 32}0.33333      {col 46}1/2    {col 58}mu_1
{col 8}   1   {col 18}0.00000   {col 32}-0.03704     {col 46}1/4    {col 58}mu_2
{col 8}   2   {col 18}0.00000   {col 32}-0.00648     {col 46}1/4    {col 58}mu_2
{col 8}   3   {col 18}0.00000   {col 32}-0.00238     {col 46}1/4    {col 58}mu_2
{col 8}   4   {col 18}0.00000   {col 32}-0.00115     {col 46}1/4    {col 58}mu_2
{col 8}{hline 60}

{p 4 4}{bf:Key insight:} a_p = 0 for all p >= 1. This is a fundamental
mathematical property of the recursive detrending, not a numerical error.
When trend terms are fitted (p >= 1), the first-order bias term vanishes
entirely, and power is driven solely by the second-order term through mu_2
(the second moment of c_i). This shifts the rate of shrinking from
N^{-1/2}*T^{-1} to N^{-1/4}*T^{-1}.{p_end}

{p 4 4}The value of b_p is declining in p, meaning power decreases as
higher-order trends are added. However, the rate of shrinking (kappa = 1/4)
remains constant for all p >= 1, which goes against the common belief that
kappa should continue to decrease with the trend degree.{p_end}

{marker power}{title:Power Properties}

{p 4 4}The local asymptotic distribution under H1 is given by (Westerlund 2015, eq. 5):{p_end}

{p 8 12}t-REC ~ sqrt(2N) * [alpha_N * mu_1 * a_p + alpha_N^2 * mu_2 * b_p]
/ sqrt[1 + (4/3) * mu_1 * alpha_N * a_p + mu_2 * alpha_N^2 * b_p]
+ [1 / sqrt(1 + ...)] * N(0,1){p_end}

{p 4 4}{bf:Power characteristics by trend degree:}{p_end}

{p 8 12 2}{bf:p < 1 (no trend terms):} a_p = 1/2, power is driven by mu_1 = E(c_i)
within N^{-1/2}*T^{-1}-neighborhoods. This matches the power envelope
(Moon, Perron, and Phillips 2007).{p_end}

{p 8 12 2}{bf:p >= 1 (with trend terms):} a_p = 0, power is driven by mu_2 = E(c_i^2)
within N^{-1/4}*T^{-1}-neighborhoods. The test cannot distinguish local
stationarity (c_i < 0) from local explosiveness (c_i > 0). The value of b_p
is declining in p, so power decreases with the trend degree.{p_end}

{p 4 4}{bf:Comparison with competing tests (p = 1):}{p_end}
{p 8 12 2}t-REC:  drift coefficient = -0.052*mu_2{p_end}
{p 8 12 2}t+ (Moon-Perron):  drift = -0.053*mu_2{p_end}
{p 8 12 2}lambda_UB (Breitung):  drift = 0.068*mu_2 (right-tail){p_end}
{p 8 12 2}V_NT (point-optimal):  drift = -0.075*mu_2 (power envelope){p_end}

{p 4 4}While t-REC does not attain the power envelope for p >= 1, it is the
only test that can be used for p > 1, making it uniquely valuable for testing
with higher-order polynomial trends.{p_end}

{marker interpretation}{title:Interpretation Guide}

{p 4 4}{bf:How to interpret the results:}{p_end}

{p 8 12 2}1. Look at the {bf:p-value} in the main results table. Reject the null
hypothesis of a unit root if the p-value is below your significance level.{p_end}

{p 8 12 2}2. Compare the test statistic with the {bf:critical values table}. Since
the null distribution is N(0,1), the critical values are always -2.3263 (1%),
-1.6449 (5%), and -1.2816 (10%).{p_end}

{p 8 12 2}3. The {bf:individual panel statistics} section shows the distribution of
per-panel t-statistics. High dispersion (large SD) suggests heterogeneity
across panels.{p_end}

{p 8 12 2}4. The {bf:Table 1} section shows where your chosen trend degree falls
in the asymptotic coefficient table. The current p is highlighted.{p_end}

{p 4 4}{bf:Choosing the trend degree:}{p_end}

{p 8 12 2}{cmd:trend(0)}: Use when the variable has no trend (e.g., growth rates,
inflation rates, interest rate spreads).{p_end}

{p 8 12 2}{cmd:trend(1)}: Use when the variable has a linear trend (e.g., GDP,
industrial production, population).{p_end}

{p 8 12 2}{cmd:trend(2)}: Use when the variable has a quadratic trend (e.g., CO2
emissions with accelerating growth, urbanization rates).{p_end}

{p 8 12 2}{cmd:trend(3)}: Use when the variable has a cubic trend or to robustify
against unknown nonlinear trending behavior.{p_end}

{p 4 4}{bf:When to use the robust version:}{p_end}

{p 8 12 2}Use {opt robust} when you suspect serial correlation in the errors,
cross-section dependence across panels (e.g., from common shocks or
spatial spillovers), or heteroskedasticity across panels. In empirical
work, the robust version is generally recommended.{p_end}

{marker graphs}{title:Diagnostics and Graphs}

{p 4 4}By default, {cmd:xtrec} generates a combined diagnostic graph with two panels:{p_end}

{p 8 12 2}{bf:Recursively Detrended Residuals}: A density plot of the pooled
recursively detrended residuals overlaid with a kernel density estimate and a
Normal fit. Under H0, these should be approximately Gaussian.{p_end}

{p 8 12 2}{bf:Cumulative Sum Paths}: A spaghetti plot of the individual
cumulative sum processes R_{i,t,p} across panels. Under H0 (unit root), these
paths should exhibit random-walk-like behavior. The bold line shows the
cross-section mean.{p_end}

{p 4 4}Use {opt nograph} to suppress these plots.{p_end}

{marker saved}{title:Saved Values}

{p 4 4}{cmd:xtrec} stores the following in {cmd:r()}:{p_end}

{col 4} Scalars
{col 8}{cmd: r(trec)}{col 30} t-REC test statistic (when {opt robust} not used)
{col 8}{cmd: r(trrec)}{col 30} t-RREC test statistic (when {opt robust} used)
{col 8}{cmd: r(pvalue)}{col 30} p-value (from left-tail standard Normal)
{col 8}{cmd: r(N)}{col 30} number of panels
{col 8}{cmd: r(T)}{col 30} number of time periods
{col 8}{cmd: r(T_eff)}{col 30} effective time periods after detrending
{col 8}{cmd: r(trend)}{col 30} fitted trend degree p
{col 8}{cmd: r(a_p)}{col 30} coefficient a_p from Table 1
{col 8}{cmd: r(b_p)}{col 30} coefficient b_p from Table 1
{col 8}{cmd: r(sigma2)}{col 30} estimated error variance sigma^2_eps
{col 8}{cmd: r(kappa)}{col 30} rate of shrinking (0.5 for p<1, 0.25 for p>=1)
{col 8}{cmd: r(maxlag)}{col 30} BIC-selected lag order (robust version only)
{col 8}{cmd: r(ps_mean)}{col 30} mean of individual panel t-statistics
{col 8}{cmd: r(ps_median)}{col 30} median of individual panel t-statistics
{col 8}{cmd: r(ps_sd)}{col 30} std. dev. of individual panel t-statistics
{col 8}{cmd: r(ps_min)}{col 30} minimum individual panel t-statistic
{col 8}{cmd: r(ps_max)}{col 30} maximum individual panel t-statistic

{col 4} Macros
{col 8}{cmd: r(test)}{col 30} test name ("t-REC" or "t-RREC")
{col 8}{cmd: r(varname)}{col 30} variable tested
{col 8}{cmd: r(panelvar)}{col 30} panel variable
{col 8}{cmd: r(timevar)}{col 30} time variable

{marker examples}{title:Examples}

{p 4 4}{bf:Example 1: Basic t-REC test (constant only):}{p_end}

{p 8}{stata webuse grunfeld, clear}{p_end}
{p 8}{stata xtset company year}{p_end}
{p 8}{stata xtrec invest}{p_end}

{p 4 4}{bf:Example 2: t-REC with linear trend:}{p_end}

{p 8}{stata xtrec invest, trend(1)}{p_end}

{p 4 4}{bf:Example 3: t-REC with quadratic trend:}{p_end}

{p 8}{stata xtrec invest, trend(2)}{p_end}

{p 4 4}{bf:Example 4: t-REC with cubic trend:}{p_end}

{p 8}{stata xtrec invest, trend(3)}{p_end}

{p 4 4}{bf:Example 5: Robust t-RREC with linear trend:}{p_end}

{p 8}{stata xtrec invest, trend(1) robust}{p_end}

{p 4 4}{bf:Example 6: Robust t-RREC with automatic BIC lag selection:}{p_end}

{p 8}{stata xtrec invest, trend(1) robust maxlag(4) nograph}{p_end}

{p 4 4}{bf:Example 7: Compare all trend degrees:}{p_end}

{p 8}{stata "forvalues p = 0/3 { xtrec invest, trend(`p') nograph }"}{p_end}

{p 4 4}{bf:Example 8: Test on log-transformed variable:}{p_end}

{p 8}{stata gen log_invest = ln(invest)}{p_end}
{p 8}{stata xtrec log_invest, trend(2)}{p_end}

{p 4 4}{bf:Example 9: Suppress table, show only graphs:}{p_end}

{p 8}{stata xtrec invest, trend(1) notable}{p_end}

{p 4 4}{bf:Example 10: Full analysis with all options:}{p_end}

{p 8}{stata xtrec invest, trend(1) robust level(99)}{p_end}

{marker references}{title:References}

{p 4 8}Westerlund, J. (2015). The effect of recursive detrending on panel unit root tests.
{it:Journal of Econometrics} 185(2), 453-467.
{browse "http://dx.doi.org/10.1016/j.jeconom.2014.06.015":doi:10.1016/j.jeconom.2014.06.015}{p_end}

{p 4 8}Moon, H.R., Perron, B. and Phillips, P.C.B. (2007). Incidental trends and the power
of panel unit root tests. {it:Journal of Econometrics} 141, 416-459.{p_end}

{p 4 8}Moon, H.R. and Perron, B. (2008). Asymptotic local power of pooled t-ratio tests
for unit roots in panels with fixed effects. {it:Econometrics Journal} 11, 80-104.{p_end}

{p 4 8}Pesaran, M.H. (2007). A simple panel unit root test in presence of cross-section
dependence. {it:Journal of Applied Econometrics} 22, 265-312.{p_end}

{p 4 8}Bai, J. and Ng, S. (2004). A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72, 1127-1177.{p_end}

{p 4 8}Breitung, J. (2000). The local power of some unit root tests for panel data.
In Baltagi, B. (Ed.), {it:Advances in Econometrics}, Vol. 15, pp. 161-178.{p_end}

{p 4 8}Moon, H.R. and Phillips, P.C.B. (2000). Estimation of autoregressive roots near unity
using panel data. {it:Econometric Theory} 16, 927-997.{p_end}

{p 4 8}Levin, A., Lin, C.F. and Chu, C.J. (2002). Unit root tests in panel data:
asymptotic and finite-sample properties. {it:Journal of Econometrics} 108, 1-24.{p_end}

{p 4 8}Im, K.S., Pesaran, M.H. and Shin, Y. (2003). Testing for unit roots in
heterogeneous panels. {it:Journal of Econometrics} 115, 53-74.{p_end}

{p 4 8}Shin, D.W. and So, B.S. (2001). Recursive mean adjustment for unit root tests.
{it:Journal of Time Series Analysis} 22, 595-612.{p_end}

{marker citation}{title:Citation}

{p 4 4}If you use {cmd:xtrec} in published work, please cite:{p_end}

{p 8 8}Roudane, M. (2026). xtrec: Panel unit root test based on recursive detrending
in Stata. Statistical Software Components, Boston College Department of Economics.{p_end}

{p 8 8}Westerlund, J. (2015). The effect of recursive detrending on panel unit root tests.
{it:Journal of Econometrics} 185(2), 453-467.{p_end}

{p 4 4}BibTeX:{p_end}

{p 8 8}@article{c -(}westerlund2015,{p_end}
{p 10 10}title={c -(}The effect of recursive detrending on panel unit root tests{c )-},{p_end}
{p 10 10}author={c -(}Westerlund, Joakim{c )-},{p_end}
{p 10 10}journal={c -(}Journal of Econometrics{c )-},{p_end}
{p 10 10}volume={c -(}185{c )-},{p_end}
{p 10 10}number={c -(}2{c )-},{p_end}
{p 10 10}pages={c -(}453--467{c )-},{p_end}
{p 10 10}year={c -(}2015{c )-}{p_end}
{p 8 8}{c )-}{p_end}

{marker also}{title:Also see}

{p 4 4}Related Stata commands:{p_end}

{p 8 12 2}{help xtunitroot} — Panel unit root tests (LLC, IPS, Fisher, Hadri){p_end}
{p 8 12 2}{help dfuller} — Augmented Dickey-Fuller unit root test{p_end}
{p 8 12 2}{help pperron} — Phillips-Perron unit root test{p_end}

{p 4 4}User-written commands (install via {cmd:ssc install}): {help pescadf}, {help xtcips}, {help multipurt}{p_end}

{marker about}{title:About}

{pstd}
{cmd:xtrec} implements the recursively detrended panel unit root tests
proposed by Westerlund (2015). The key innovation is that the null distribution
of the test statistic is asymptotically invariant to both the true and
fitted trend polynomial, eliminating the need for trend-degree-specific
correction factors that plague existing panel unit root tests. This makes
the test uniquely suitable for testing with higher-order polynomial trends
(quadratic, cubic, etc.) which were previously intractable.{p_end}

{pstd}
The command is implemented in Mata for computational speed and provides
comprehensive diagnostic output including per-panel statistics, the full
Table 1 from the paper, power properties, and methodology details.{p_end}

{pstd}
Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
