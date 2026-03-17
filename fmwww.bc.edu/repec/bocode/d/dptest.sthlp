{smcl}
{* *! version 2.0.0  14mar2026}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{vieweralsosee "[TS] pperron" "help pperron"}{...}
{viewerjumpto "Syntax" "dptest##syntax"}{...}
{viewerjumpto "Description" "dptest##description"}{...}
{viewerjumpto "Options" "dptest##options"}{...}
{viewerjumpto "Methods" "dptest##methods"}{...}
{viewerjumpto "Interpretation" "dptest##interpretation"}{...}
{viewerjumpto "Critical Values" "dptest##critvals"}{...}
{viewerjumpto "Stored Results" "dptest##results"}{...}
{viewerjumpto "Examples" "dptest##examples"}{...}
{viewerjumpto "Diagnostics" "dptest##diagnostics"}{...}
{viewerjumpto "References" "dptest##references"}{...}
{viewerjumpto "Author" "dptest##author"}{...}

{title:Title}

{phang}
{bf:dptest} {hline 2} Multiple unit root and cointegration tests for I(2) processes


{marker syntax}{...}
{title:Syntax}

{phang}{ul:Unit root testing:}{p_end}

{p 8 17 2}
{cmd:dptest}
{it:varname}
{ifin}
[{cmd:,} {it:options}]

{phang}{ul:Cointegration testing:}{p_end}

{p 8 17 2}
{cmd:dptest}
{it:depvar} {it:indepvars}
{ifin}
{cmd:,} {cmd:test(coint)} {cmd:i2vars(}{it:varlist}{cmd:)} [{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt test(string)}}test to run: {bf:dp}, {bf:hf}, {bf:hz}, {bf:coint}, or {bf:all} (default){p_end}
{synopt:{opt maxd:iff(#)}}maximum differencing order for DP test; default is {cmd:3}{p_end}
{synopt:{opt maxl:ag(#)}}maximum AR lag augmentation; default uses Schwert rule{p_end}
{synopt:{opt det(string)}}deterministic terms: {bf:none}, {bf:const} (default), {bf:trend}, {bf:qtrend}{p_end}
{synopt:{opt l:evel(#)}}significance level: {bf:1}, {bf:5} (default), or {bf:10}{p_end}
{synopt:{opt band:width(#)}}Newey-West bandwidth for Z(F*); default uses Schwert rule{p_end}
{synopt:{opt i2vars(varlist)}}I(2) regressors for cointegration test{p_end}
{synopt:{opt graph}}produce diagnostic graphs (line plots + ACF){p_end}
{synopt:{opt not:able}}suppress output tables{p_end}
{synopt:{opt crit(string)}}lag selection criterion: {bf:bic} (default) or {bf:aic}{p_end}
{synoptline}
{p 4 6 2}The data must be {cmd:tsset} before using {cmd:dptest}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dptest} implements four complementary tests for determining the order of
integration in time series and for testing cointegration when both I(1) and I(2)
variables are present:

{phang2}1. {bf:Dickey-Pantula (1987)} sequential t* procedure for multiple unit roots{p_end}
{phang2}2. {bf:Hasza-Fuller (1979)} joint F test (Phi statistics) for double unit roots{p_end}
{phang2}3. {bf:Haldrup (1994 JBES)} semiparametric Z(F*) test for double unit roots{p_end}
{phang2}4. {bf:Haldrup (1994 JoE)} residual-based cointegration ADF test with I(1) and I(2) variables{p_end}

{pstd}
Methods 1-3 are {bf:unit root tests} that determine whether a series is I(0), I(1),
or I(2). Method 4 is a {bf:cointegration test} that determines whether variables of
mixed integration orders share a long-run equilibrium.

{pstd}
{bf:Why is this package needed?}  Standard unit root tests ({cmd:dfuller}, {cmd:pperron},
{cmd:dfgls}) only distinguish between I(0) and I(1). If a series is actually I(2),
applying {cmd:dfuller} to its first difference may incorrectly conclude it is
stationary, leading to spurious regression problems. {cmd:dptest} tests specifically
for {it:multiple} unit roots by testing from the highest order downward, or by
jointly testing for two unit roots. This is essential in macroeconomic and financial
applications where price levels, money supply, or nominal GDP may be I(2).


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt test(string)} specifies which test to run.

{p 12 12 2}
{bf:dp} {hline 2} Dickey-Pantula sequential t* test. Tests multiple unit roots by
working from the highest order downward. Best when you suspect up to 2 or 3 unit
roots and want a definitive integration order.
{p_end}

{p 12 12 2}
{bf:hf} {hline 2} Hasza-Fuller joint F test. Tests the null of exactly two unit
roots against at most one. A parametric approach that assumes iid errors.
{p_end}

{p 12 12 2}
{bf:hz} {hline 2} Haldrup semiparametric Z(F*) test. Same null as {bf:hf}, but
robust to serial correlation and heteroskedasticity via Newey-West correction.
Preferred when errors may be autocorrelated.
{p_end}

{p 12 12 2}
{bf:coint} {hline 2} Haldrup cointegration ADF test. Tests whether variables of
mixed integration orders (some I(1), some I(2)) cointegrate. Requires
{cmd:i2vars()}.
{p_end}

{p 12 12 2}
{bf:all} {hline 2} (default) Runs the three unit root tests (dp, hf, hz)
together, providing a comprehensive assessment. Does not run the cointegration
test.
{p_end}

{phang}
{opt maxdiff(#)} sets the maximum differencing order for the Dickey-Pantula test.
Default is {cmd:3}, which tests for up to I(3). In most applications, {cmd:maxdiff(2)}
is sufficient. Setting {cmd:maxdiff(3)} is appropriate when you suspect the series
may need triple differencing (rare, but possible in nominal price series).

{phang}
{opt maxlag(#)} sets the maximum number of augmenting lags. If not specified,
the default is computed using the Schwert (1989) rule: int(12*(N/100)^0.25).
Lags are selected via BIC minimization over {0, 1, ..., maxlag}. Higher
values provide more insurance against serial correlation but reduce degrees
of freedom.

{phang}
{opt det(string)} specifies deterministic terms included in test regressions.

{p 12 12 2}
{bf:none} {hline 2} No constant or trend. Appropriate only when the series has
no drift and no trend under the alternative.
{p_end}

{p 12 12 2}
{bf:const} {hline 2} (default) Intercept only. Appropriate for most economic time
series that may have a nonzero mean under the alternative.
{p_end}

{p 12 12 2}
{bf:trend} {hline 2} Intercept plus linear trend. Use when the series exhibits a
clear linear trend under the alternative hypothesis.
{p_end}

{p 12 12 2}
{bf:qtrend} {hline 2} Intercept plus quadratic trend. Use when the series appears
to have a nonlinear (quadratic) trend. Critical values from Haldrup (1994 JBES)
Tables 3-4 are used. This is rare in practice but applicable to some demographic
or cumulative series.
{p_end}

{phang}
{opt level(#)} specifies the significance level for hypothesis testing. Allowed
values are {bf:1}, {bf:5} (default), or {bf:10}. Critical values are adjusted
accordingly. Use {bf:1}% for conservative testing (lower risk of false rejection)
or {bf:10}% for more liberal testing (higher power).

{phang}
{opt bandwidth(#)} sets the bandwidth for the Newey-West long-run variance
estimator used in the Haldrup Z(F*) test. Default uses the Schwert (1989) rule:
int(4*(N/100)^0.25). The Bartlett kernel is always used. Higher bandwidth allows
more autocorrelation lags in the variance estimate.

{phang}
{opt i2vars(varlist)} specifies which independent variables are I(2). Required
for {cmd:test(coint)}. Variables in {it:indepvars} not listed in {cmd:i2vars()}
are treated as I(1). The count of I(1) variables (m1) and I(2) variables (m2)
determines which critical value table is used. Tables cover m1 = {0,...,4} and
m2 = {1,2}.

{phang}
{opt graph} produces two sets of diagnostic graphs: (1) line plots of the
series in levels, first differences, and second differences; (2) autocorrelation
function (ACF) plots for each transformation. Visual inspection of these plots
helps confirm the test results. The level series of an I(2) process will show
a smooth, trending path; its first difference will look like a random walk;
and only its second difference will appear stationary.

{phang}
{opt notable} suppresses all output tables. Results are still stored in {cmd:r()}.
Useful for Monte Carlo simulations or batch processing.

{phang}
{opt crit(string)} specifies the information criterion for lag selection:
{bf:bic} (default) or {bf:aic}. BIC tends to select more parsimonious models;
AIC may include more lags.


{marker methods}{...}
{title:Methods and Formulas}

{dlgtab:Method 1: Dickey-Pantula (1987) Sequential t*}

{pstd}
{bf:When to use:} When you want to determine the exact integration order of a
series (I(0), I(1), I(2), or I(3)). This is the most general of the three unit
root tests.

{pstd}
{bf:Why it works:} Dickey and Pantula (1987) show that testing for unit roots
must proceed from the highest order downward. Starting with the standard ADF
test for one unit root when the series is I(2) leads to size distortions and
incorrect conclusions. Their sequential procedure avoids this by first testing
the most restrictive null hypothesis.

{pstd}
{bf:Model specification:} Suppose maxdiff = p. The LHS of the test regression
is the p-th difference: Delta^p Y_t. At step d (testing H0: d unit roots), the
key regressor is Delta^{d-1} Y_{t-1}, with control variables
Delta^d Y_{t-1}, ..., Delta^{p-1} Y_{t-1}. The t-ratio on the key regressor
is compared to Fuller (1976) tau critical values.

{pstd}
{bf:Decision rule:} If t* < CV, reject H0 (the series has fewer than d unit
roots) and move to the next step. If t* >= CV, do not reject, and the series
is declared I(d). The procedure stops at the first non-rejection.

{pstd}
{bf:Augmentation:} Lags of the LHS variable are added and selected by BIC to
account for serial correlation in the errors.

{dlgtab:Method 2: Hasza-Fuller (1979) Joint F Test}

{pstd}
{bf:When to use:} When you specifically want to test I(2) vs. I(1) or I(0).
This test has greater power than the sequential t* when the true DGP is I(2),
because it tests both unit root restrictions jointly.

{pstd}
{bf:Model specification:} The series is reparameterized as:

{p 8 8 2}
Delta^2 Y_t = (alpha - 1)Y_{t-1} + (beta - 1)Delta Y_{t-1} + sum_j delta_j Delta^2 Y_{t-j} + e_t

{pstd}
The null hypothesis H0: alpha = beta = 1 (two unit roots) is tested using an
F statistic. Five Phi statistics are available:

{p 8 8 2}
{bf:Phi_1(2)} {hline 2} No deterministics. Tests alpha = beta = 1 only.{p_end}
{p 8 8 2}
{bf:Phi_2(2)} {hline 2} With intercept. Tests alpha = beta = 1 only.{p_end}
{p 8 8 2}
{bf:Phi_3(2)} {hline 2} With intercept + trend. Tests alpha = beta = 1 only.{p_end}
{p 8 8 2}
{bf:Phi_QT}  {hline 2} With intercept + quadratic trend (Haldrup JBES extension).{p_end}

{pstd}
{bf:Decision rule:} If F > CV, reject H0 (evidence against two unit roots).
Note: This is a right-tail test.

{dlgtab:Method 3: Haldrup (1994 JBES) Semiparametric Z(F*)}

{pstd}
{bf:When to use:} When you want to test I(2) vs. I(1) but are concerned about
serial correlation or heteroskedasticity in the errors. This test is robust
where the Hasza-Fuller test may have size distortions.

{pstd}
{bf:Model specification:} The test first detrends the series (demean, detrend,
or quadratic detrend depending on {cmd:det()}). Then it runs the HF regression
on the detrended series without a constant (since deterministics have already
been removed). The F statistic is then adjusted using a Newey-West long-run
variance estimate:

{p 8 8 2}Z(F*) = (s^2 / sigma^2) * F_raw

{pstd}
where s^2 is the short-run variance (RSS/N) and sigma^2 is the Newey-West
long-run variance using a Bartlett kernel with the specified bandwidth.

{pstd}
{bf:Critical values:} By Haldrup (1994 JBES) Theorem 2, Z(F*) has the same
asymptotic distribution as the HF F statistic, so the same critical value
tables apply. For {cmd:det(qtrend)}, extended critical values from Haldrup JBES
Tables 3-4 are used.

{pstd}
{bf:Decision rule:} Same as HF: reject H0 (two unit roots) if Z(F*) > CV.

{dlgtab:Method 4: Haldrup (1994 JoE) Cointegration ADF}

{pstd}
{bf:When to use:} When your system contains variables of different integration
orders (some I(1), some I(2)) and you want to test whether they cointegrate.
Standard Engle-Granger cointegration tests assume all variables are I(1);
Haldrup extends this to mixed I(1)/I(2) systems.

{pstd}
{bf:Model specification:} This is a two-step Engle-Granger procedure:

{p 8 8 2}
Step 1: Run cointegration regression: Y_t = b1*X1_t + b2*X2_t + ... + u_t
where X1 variables are I(1) and X2 variables are I(2).{p_end}

{p 8 8 2}
Step 2: Test the residuals u_hat for a unit root using ADF with no constant
(residuals have zero mean by construction).{p_end}

{pstd}
If the ADF t statistic on the residuals is more negative than the critical
value, reject the null of no cointegration.

{pstd}
{bf:Critical values:} These depend on (m1, m2) = (number of I(1) regressors,
number of I(2) regressors). Tables from Haldrup (1994 JoE, Table 1) cover
m1 = {0,...,4} and m2 = {1,2} at sample sizes n = {25, 50, 100, 250, 500}.

{pstd}
{bf:Key distinction:} Unlike standard cointegration tests, the null here is
that the residuals are I(1), not I(0). This is a {it:left-tail} test:
reject if ADF statistic < CV.


{marker interpretation}{...}
{title:How to Interpret the Output}

{dlgtab:Reading the Header}

{pstd}
The header shows the variable name, sample size, deterministic specification,
maximum lag order, significance level, and (for Z(F*)) the bandwidth. Verify
these match your intentions before reading the test results.

{dlgtab:Panel A — Sequential t*}

{pstd}
The table shows one row per step. For each step d, the H0 column shows the
null hypothesis (d unit roots), the t* column shows the test statistic, and
the Decision column shows whether H0 is rejected.

{p 8 8 2}
{bf:If all nulls are rejected:} The series is I(0) — it is stationary.{p_end}
{p 8 8 2}
{bf:If the first non-rejection is at d=1:} The series is I(1).{p_end}
{p 8 8 2}
{bf:If the first non-rejection is at d=2:} The series is I(2).{p_end}
{p 8 8 2}
{bf:If no null is rejected:} The series is I(maxdiff), the maximum order tested.{p_end}

{pstd}
{it:Common pitfall:} If t* values are close to the critical value boundary,
results may be sensitive to the significance level. Run with different levels
({cmd:level(1)}, {cmd:level(5)}, {cmd:level(10)}) to check robustness.

{dlgtab:Panel B — Joint F Test}

{pstd}
A single F statistic is reported along with critical values at 1%, 5%, and 10%.

{p 8 8 2}
{bf:F > CV:} Reject H0. The series does {bf:not} have two unit roots. It is
at most I(1). A subsequent standard ADF test can determine if it is I(1) or I(0).{p_end}
{p 8 8 2}
{bf:F <= CV:} Cannot reject H0. Evidence is consistent with I(2).{p_end}

{pstd}
{it:Note:} This is a right-tail test, unlike the standard ADF which is left-tail.

{dlgtab:Panel C — Z(F*)}

{pstd}
Same interpretation as Panel B, but the test statistic is corrected for serial
correlation. Compare Z(F*) with the same critical values as the HF F test.

{pstd}
The output also shows the short-run variance s^2 and the long-run variance
sigma^2. If sigma^2 >> s^2, this indicates substantial serial correlation in
the errors. In such cases, the uncorrected HF test may over-reject the null,
and Z(F*) provides a more reliable result.

{pstd}
{it:When HF and Z(F*) disagree:} If HF rejects but Z(F*) does not, the
rejection by HF is likely a size distortion caused by serial correlation. Trust
Z(F*) in this case.

{dlgtab:Panel D — Cointegration ADF}

{pstd}
Reports the ADF statistic on cointegration residuals along with critical values
that account for the number and integration order of regressors.

{p 8 8 2}
{bf:ADF < CV:} Reject H0. Evidence of cointegration — a long-run
equilibrium relationship exists among the variables.{p_end}
{p 8 8 2}
{bf:ADF >= CV:} Cannot reject H0. No evidence of cointegration.{p_end}

{pstd}
The critical values here are more negative than standard ADF critical values
because the residuals are generated regressors (Haldrup 1994 JoE accounts for
this).

{dlgtab:Summary Table}

{pstd}
When running {cmd:test(all)}, the summary table at the bottom shows the
estimated integration order from each method side by side. Ideally, all
three methods should agree. Disagreement suggests either:

{p 8 8 2}
(a) the series is borderline (near-I(2) with a large but finite AR root), or{p_end}
{p 8 8 2}
(b) the deterministic specification may be inappropriate — try different
{cmd:det()} options, or{p_end}
{p 8 8 2}
(c) the sample size is too small for reliable inference.{p_end}


{marker critvals}{...}
{title:Critical Values}

{pstd}
Critical value tables are hardcoded from five sources:

{phang2}1. {bf:Fuller (1976) Table 8.5.2}: tau statistics for the DP sequential t*
test at n = {25, 50, 100, 250, 500+}. Three sets: no constant, constant,
constant + trend.{p_end}

{phang2}2. {bf:Hasza & Fuller (1979) Table 4.1}: Phi_1(2), Phi_2(2), Phi_3(2)
at n = {25, 50, 100, 250, 500, infinity} and percentiles
{50, 80, 90, 95, 97.5, 99}.{p_end}

{phang2}3. {bf:Haldrup (1994 JBES) Table 3}: Phi with quadratic trend at
n = {25, 50, 100, 250, 500}.{p_end}

{phang2}4. {bf:Haldrup (1994 JBES) Table 4}: DF t-test with quadratic trend.{p_end}

{phang2}5. {bf:Haldrup (1994 JoE) Table 1}: Cointegration ADF critical values
for m2 = {1,2} and m1 = {0,...,4} at n = {25, 50, 100, 250, 500} and
significance levels {1%, 2.5%, 5%, 10%}.{p_end}

{pstd}
Sample size matching uses the nearest lower bracket. For example, n = 73 uses
the n = 50 critical values. This is conservative (critical values are wider for
smaller n).


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:dptest} stores the following in {cmd:r()}:

{pstd}{bf:Common:}{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(N)}}effective sample size{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(det)}}deterministic specification{p_end}
{synopt:{cmd:r(level)}}significance level{p_end}
{synopt:{cmd:r(maxlag)}}maximum lag order{p_end}
{synopt:{cmd:r(bandwidth)}}Newey-West bandwidth{p_end}

{pstd}{bf:Dickey-Pantula (test dp):}{p_end}
{synopt:{cmd:r(dp_d)}}estimated integration order{p_end}
{synopt:{cmd:r(dp_tstar_1)}}t* for step 1{p_end}
{synopt:{cmd:r(dp_tstar_2)}}t* for step 2{p_end}
{synopt:{cmd:r(dp_tstar_3)}}t* for step 3 (if maxdiff >= 3){p_end}

{pstd}{bf:Hasza-Fuller (test hf):}{p_end}
{synopt:{cmd:r(hf_F)}}F statistic{p_end}
{synopt:{cmd:r(hf_d)}}estimated order (2 = I(2), 1 = at most I(1)){p_end}
{synopt:{cmd:r(hf_cv1)}}critical value at 1%{p_end}
{synopt:{cmd:r(hf_cv5)}}critical value at 5%{p_end}
{synopt:{cmd:r(hf_cv10)}}critical value at 10%{p_end}
{synopt:{cmd:r(hf_lags)}}selected augmentation lags{p_end}

{pstd}{bf:Haldrup Z(F*) (test hz):}{p_end}
{synopt:{cmd:r(hz_ZF)}}Z(F*) statistic{p_end}
{synopt:{cmd:r(hz_d)}}estimated order (2 = I(2), 1 = at most I(1)){p_end}
{synopt:{cmd:r(hz_sigma2)}}Newey-West long-run variance{p_end}
{synopt:{cmd:r(hz_s2)}}short-run variance{p_end}
{synopt:{cmd:r(hz_lambda)}}half-variance correction{p_end}

{pstd}{bf:Cointegration (test coint):}{p_end}
{synopt:{cmd:r(coint_adf)}}ADF statistic on residuals{p_end}
{synopt:{cmd:r(coint_cv)}}critical value at specified level{p_end}
{synopt:{cmd:r(coint_cv1)}}critical value at 1%{p_end}
{synopt:{cmd:r(coint_cv5)}}critical value at 5%{p_end}
{synopt:{cmd:r(coint_cv10)}}critical value at 10%{p_end}
{synopt:{cmd:r(coint_reject)}}1 if H0 rejected, 0 otherwise{p_end}
{synopt:{cmd:r(coint_m1)}}number of I(1) regressors{p_end}
{synopt:{cmd:r(coint_m2)}}number of I(2) regressors{p_end}
{synopt:{cmd:r(coint_lags)}}selected augmentation lags{p_end}


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Basic unit root testing}

{pstd}Setup:{p_end}
{phang2}{cmd:. webuse air2}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Run all three unit root tests with default settings (constant, 5%):{p_end}
{phang2}{cmd:. dptest air}{p_end}

{pstd}Interpretation: If the DP test concludes I(1), HF fails to reject, and
Z(F*) fails to reject, then the series likely has two unit roots (I(2)).
If all three methods agree on I(1), the series needs only first differencing.{p_end}

{dlgtab:Example 2: Choosing deterministic terms}

{pstd}If the series shows a clear upward trend, include a trend:{p_end}
{phang2}{cmd:. dptest air, test(dp) det(trend)}{p_end}

{pstd}If you suspect the trend is nonlinear (e.g., accelerating growth):{p_end}
{phang2}{cmd:. dptest air, test(hz) det(qtrend)}{p_end}

{pstd}For series centered around zero with no drift:{p_end}
{phang2}{cmd:. dptest air, test(hf) det(none)}{p_end}

{dlgtab:Example 3: Simulated I(2) process}

{pstd}Generate and test an I(2) process:{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen eps = rnormal()}{p_end}
{phang2}{cmd:. gen dy = sum(eps)}{p_end}
{phang2}{cmd:. gen y = sum(dy)}{p_end}
{phang2}{cmd:. dptest y}{p_end}

{pstd}Expected: DP should find I(2), HF and Z(F*) should not reject H0 (both
indicating two unit roots). The {cmd:graph} option helps confirm visually:{p_end}
{phang2}{cmd:. dptest y, graph}{p_end}

{dlgtab:Example 4: Simulated I(1) process}

{phang2}{cmd:. gen y_rw = sum(rnormal())}{p_end}
{phang2}{cmd:. dptest y_rw}{p_end}

{pstd}Expected: DP should find I(1). HF and Z(F*) should reject H0 of two unit
roots, concluding at most I(1).{p_end}

{dlgtab:Example 5: Simulated I(0) process}

{phang2}{cmd:. gen y_stat = rnormal()}{p_end}
{phang2}{cmd:. dptest y_stat}{p_end}

{pstd}Expected: DP should find I(0). HF and Z(F*) should reject H0 (the series
does not have two unit roots).{p_end}

{dlgtab:Example 6: Significance level sensitivity}

{pstd}Check how conclusions change across significance levels:{p_end}
{phang2}{cmd:. dptest air, level(1)}{p_end}
{phang2}{cmd:. dptest air, level(5)}{p_end}
{phang2}{cmd:. dptest air, level(10)}{p_end}

{pstd}If results change between 5% and 10%, the evidence is borderline. Use
the {cmd:graph} option and the ACF to make a judgment call.{p_end}

{dlgtab:Example 7: Cointegration with I(1) and I(2) variables}

{pstd}Generate a cointegrated system: y = x2 + 0.5*x1 + v, where x1 ~ I(1),
x2 ~ I(2), and v ~ I(1):{p_end}
{phang2}{cmd:. gen e1 = rnormal()}{p_end}
{phang2}{cmd:. gen e2 = rnormal()}{p_end}
{phang2}{cmd:. gen x1 = sum(e1)}{p_end}
{phang2}{cmd:. gen dx2 = sum(e2)}{p_end}
{phang2}{cmd:. gen x2 = sum(dx2)}{p_end}
{phang2}{cmd:. gen v = sum(rnormal())}{p_end}
{phang2}{cmd:. gen y_c = x2 + 0.5*x1 + v}{p_end}
{phang2}{cmd:. dptest y_c x1 x2, test(coint) i2vars(x2)}{p_end}

{pstd}Here m1 = 1 (x1 is I(1)) and m2 = 1 (x2 is I(2)). If the ADF statistic
is sufficiently negative, we reject H0 of no cointegration and conclude that
y, x1, and x2 share a long-run equilibrium.{p_end}

{dlgtab:Example 8: Multiple I(2) regressors}

{phang2}{cmd:. gen dx3 = sum(rnormal())}{p_end}
{phang2}{cmd:. gen x3 = sum(dx3)}{p_end}
{phang2}{cmd:. gen y_c2 = x2 + x3 + 0.3*x1 + v}{p_end}
{phang2}{cmd:. dptest y_c2 x1 x2 x3, test(coint) i2vars(x2 x3)}{p_end}

{pstd}Here m1 = 1, m2 = 2. Critical values are more negative (harder to reject)
because more regressors increase the chance of spurious cointegration.{p_end}

{dlgtab:Example 9: Using stored results in programs}

{pstd}Suppress output and access results programmatically:{p_end}
{phang2}{cmd:. dptest air, notable}{p_end}
{phang2}{cmd:. display "DP order: " r(dp_d)}{p_end}
{phang2}{cmd:. display "HF F stat: " r(hf_F)}{p_end}
{phang2}{cmd:. display "Z(F*): " r(hz_ZF)}{p_end}

{dlgtab:Example 10: Monte Carlo size simulation}

{pstd}Evaluate the size of the HF test under H0:{p_end}
{phang2}{cmd:. local reps 1000}{p_end}
{phang2}{cmd:. local rejects 0}{p_end}
{phang2}{cmd:. forval i = 1/`reps' {c -(}}{p_end}
{phang2}{cmd:.     qui drop _all}{p_end}
{phang2}{cmd:.     qui set obs 100}{p_end}
{phang2}{cmd:.     qui gen t = _n}{p_end}
{phang2}{cmd:.     qui tsset t}{p_end}
{phang2}{cmd:.     qui gen y = sum(sum(rnormal()))}{p_end}
{phang2}{cmd:.     qui dptest y, test(hf) notable}{p_end}
{phang2}{cmd:.     if r(hf_d) == 1  local rejects = `rejects' + 1}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. display "Rejection rate: " `rejects'/`reps'}{p_end}

{pstd}Under H0 (true I(2)), the rejection rate should be close to 5% at the
5% significance level.{p_end}


{marker diagnostics}{...}
{title:Diagnostics and Troubleshooting}

{pstd}
{bf:Sample size too small:} {cmd:dptest} requires at least 25 observations.
With very small samples (n < 50), critical values may be imprecise. Results
should be interpreted with caution.{p_end}

{pstd}
{bf:Missing values:} The command uses {cmd:marksample} and drops missing
observations before testing. Be aware that differencing and lagging reduce
the effective sample size by {cmd:maxdiff + selected_lags} observations.{p_end}

{pstd}
{bf:Structural breaks:} None of these tests account for structural breaks.
If breaks are present, the unit root tests may incorrectly fail to reject
(the series appears more persistent). Consider using break-robust alternatives
or testing subsamples.{p_end}

{pstd}
{bf:Seasonal data:} For seasonal data, consider seasonal differencing first
or including seasonal dummies (not yet supported). The standard tests assume
non-seasonal integration.{p_end}


{marker references}{...}
{title:References}

{phang}
Dickey, D.A. and S.G. Pantula. 1987.
Determining the order of differencing in autoregressive processes.
{it:Journal of Business & Economic Statistics} 5(4): 455-461.

{phang}
Fuller, W.A. 1976.
{it:Introduction to Statistical Time Series}. New York: Wiley.

{phang}
Haldrup, N. 1994.
Semiparametric tests for double unit roots.
{it:Journal of Business & Economic Statistics} 12(1): 109-122.

{phang}
Haldrup, N. 1994.
The asymptotics of single-equation cointegration regressions with
I(1) and I(2) variables.
{it:Journal of Econometrics} 63(1): 153-181.

{phang}
Hasza, D.P. and W.A. Fuller. 1979.
Estimation for autoregressive processes with unit roots.
{it:The Annals of Statistics} 7(5): 1106-1120.

{phang}
Newey, W.K. and K.D. West. 1987.
A simple, positive semi-definite, heteroskedasticity and autocorrelation
consistent covariance matrix.
{it:Econometrica} 55(3): 703-708.

{phang}
Phillips, P.C.B. 1987.
Time series regression with a unit root.
{it:Econometrica} 55(2): 277-301.

{phang}
Schwert, G.W. 1989.
Tests for unit roots: A Monte Carlo investigation.
{it:Journal of Business & Economic Statistics} 7(2): 147-159.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{p_end}

{pstd}
Email: merwanroudane920@gmail.com{p_end}

{pstd}
Please cite as:{p_end}
{phang2}Roudane, M. 2026. {cmd:dptest}: Multiple unit root and cointegration tests
for I(2) processes. Stata package version 2.0.0.{p_end}
{smcl}
