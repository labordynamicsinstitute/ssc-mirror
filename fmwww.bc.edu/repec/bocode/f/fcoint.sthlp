{smcl}
{* *! version 1.1.0  08mar2026}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "vec" "help vec"}{...}
{viewerjumpto "Syntax" "fcoint##syntax"}{...}
{viewerjumpto "Description" "fcoint##description"}{...}
{viewerjumpto "Tests" "fcoint##tests"}{...}
{viewerjumpto "Options" "fcoint##options"}{...}
{viewerjumpto "Requirements" "fcoint##requirements"}{...}
{viewerjumpto "Methodology" "fcoint##methodology"}{...}
{viewerjumpto "Critical values" "fcoint##critvals"}{...}
{viewerjumpto "Interpretation" "fcoint##interpretation"}{...}
{viewerjumpto "Warnings" "fcoint##warnings"}{...}
{viewerjumpto "Examples" "fcoint##examples"}{...}
{viewerjumpto "Stored results" "fcoint##results"}{...}
{viewerjumpto "Graphs" "fcoint##graphs"}{...}
{viewerjumpto "References" "fcoint##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:fcoint} {hline 2}}Fourier cointegration tests for time series with smooth
structural breaks{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 18 2}
{cmd:fcoint} {depvar} {indepvars} {ifin}{cmd:,}
{opt test(testname)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:{it:Required}}
{synopt:{opt test(testname)}}test to run: {bf:fadl}, {bf:feg}, {bf:feg2},
{bf:tsong}, or {bf:all}{p_end}

{syntab:{it:Model specification}}
{synopt:{opt mod:el(string)}}deterministic: {bf:constant} (default) or
{bf:trend}{p_end}
{synopt:{opt maxf:req(#)}}max Fourier frequency; default is {bf:5}{p_end}
{synopt:{opt maxl:ag(#)}}max lag length; default = {bf:6} (FADL) or
{bf:auto} (others){p_end}
{synopt:{opt cri:terion(string)}}info criterion: {bf:aic} (default) or
{bf:bic}{p_end}
{synopt:{opt cumf:req}}use cumulative frequencies (q = 1, ..., maxfreq){p_end}
{synopt:{opt dols(#)}}DOLS leads/lags for Tsong test; 0 = auto{p_end}

{syntab:{it:Output}}
{synopt:{opt gr:aph}}produce diagnostic graphs{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fcoint} implements four Fourier-based cointegration tests for time-series
data. The tests use low-frequency Fourier (trigonometric) components to
approximate smooth structural breaks of unknown form in the deterministic
trend, {bf:without} needing to estimate the number, timing, or form of breaks.

{pstd}
This is important because conventional cointegration tests (Engle-Granger,
Johansen, ADL) can fail to detect cointegration when the equilibrium
relationship has undergone smooth structural shifts — such as gradual policy
changes, evolving market structures, or slow institutional reforms.

{pstd}
The key idea is that a Fourier expansion {it:sin(2{c pi}kt/T)} +
{it:cos(2{c pi}kt/T)} can approximate virtually {bf:any} smooth deterministic
function, including functions with multiple breaks and nonlinear shifts
(Gallant, 1981). This avoids the pitfalls of dummy-variable approaches, which
require pre-specifying break dates and forms.


{marker tests}{...}
{title:Available Tests}

{dlgtab:FADL — Fourier ADL Test}

{pstd}
{bf:Reference:} Banerjee, Arcabic & Lee (2017, {it:Economic Modelling})

{pstd}
{bf:Null hypothesis:} No cointegration (H0: {it:delta} = 0)

{pstd}
{bf:Alternative:} Cointegration (H1: {it:delta} < 0)

{pstd}
The FADL test extends the conditional error-correction (ADL) framework of
Banerjee, Dolado & Mestre (1998) by adding Fourier terms to the deterministic
component. The regression is:

{p 8 8 2}
{it:Dy_t = c + [trend] + g1*sin(2{c pi}kt/T) + g2*cos(2{c pi}kt/T)}
{it:+ delta*y_{t-1} + gamma'*x_{t-1} + phi'*Dx_t + lags + e_t}

{pstd}
The t-statistic on {it:delta} is the FADL test statistic. Rejection (large
negative value) implies cointegration after controlling for Fourier breaks.

{pstd}
{bf:Advantages:} (1) single-step procedure (no residual estimation); (2) allows
for weak exogeneity; (3) includes both short-run and long-run dynamics.

{pstd}
{bf:Lag Selection:} Nested grid search over Dy lags and each Dx_i lag separately,
using AIC or BIC. This matches the original WinRATS code exactly.

{dlgtab:FEG — Fourier Engle-Granger Test}

{pstd}
{bf:Reference:} Banerjee & Lee (Working Paper)

{pstd}
{bf:Null:} No cointegration. {bf:Alternative:} Cointegration.

{pstd}
Two-step residual-based test:

{p 8 8 2}
Step 1: Estimate long-run equation with Fourier deterministics:{break}
{it:y_t = c + [trend] + g1*sin(...) + g2*cos(...) + x_t'*beta + mu_t}

{p 8 8 2}
Step 2: ADF test on residuals (no constant):{break}
{it:D(mu_hat_t) = delta*mu_hat_{t-1} + sum(alpha_i*D(mu_hat_{t-i})) + v_t}

{pstd}
The t-statistic on {it:delta} is the FEG test statistic.

{pstd}
{bf:Lag selection:} General-to-specific — start with maxlag, drop last lag if
|t| < 1.645, repeat.

{dlgtab:FEG2 — Modified Fourier EG Test}

{pstd}
{bf:Reference:} Banerjee & Lee (Working Paper), Eq. (8)

{pstd}
{bf:Null:} No cointegration. {bf:Alternative:} Cointegration.

{pstd}
The FEG2 test augments the FEG testing regression with {it:Dx_{2,t}} to address
the common factor restriction (CFR). The standard EG test implicitly assumes
that short-run and long-run coefficients are identical. When this is violated,
the EG test loses power. The FEG2 test resolves this:

{p 8 8 2}
{it:D(mu_hat_t) = c + delta*mu_hat_{t-1} + Dx_{2,t}'*tau + epsilon_t}

{pstd}
The critical values depend on {it:rho-squared}, the long-run squared
correlation between v_t (FEG error) and epsilon_t (FEG2 error), estimated via
Bartlett kernel. When {it:rho-sq = 1}, FEG2 reduces to FEG.

{pstd}
{bf:When to use FEG2 over FEG:} Always recommended. FEG2 is never worse than
FEG, and significantly more powerful when the signal-to-noise ratio is high or
when CFR is violated. The paper recommends FEG2 for all empirical applications.

{dlgtab:Tsong — Null of Cointegration Test}

{pstd}
{bf:Reference:} Tsong, Lee, Tsai & Hu (2016, {it:Empirical Economics})

{pstd}
{bf:Null:} Cointegration EXISTS. {bf:Alternative:} No cointegration.

{pstd}
{bf:IMPORTANT:} The Tsong test reverses the null hypothesis! This is a KPSS-type
test where the null is that cointegration holds (with possible Fourier breaks).
Rejection means the variables are NOT cointegrated.

{pstd}
The test uses DOLS (Dynamic OLS) estimation with leads and lags of Dx to handle
non-strict exogeneity:

{p 8 8 2}
{it:y_t = d(t) + x_t'*beta + sum(Dx_{t-i}'*phi_i) + epsilon*_t}

{p 8 8 2}
CI_f = T^{-2} * omega_hat^{-2} * sum(S*_t^2)

{pstd}
where S*_t is the partial sum of DOLS residuals and omega_hat^2 is the
long-run variance estimated via Bartlett kernel.

{pstd}
Also reports an F-test for the significance of the Fourier component. If the
F-test is insignificant, the Shin (1994) test without Fourier terms should be
used instead.

{pstd}
{bf:When to use:} To confirm cointegration findings. Running both an H0:
no-coint test (FADL/FEG/FEG2) and an H0: coint test (Tsong) provides stronger
evidence than either alone.


{marker options}{...}
{title:Options in Detail}

{dlgtab:Required}

{phang}
{opt test(testname)} specifies which test to run. Options:

{p 12 16 2}
{bf:fadl} — FADL cointegration test (Banerjee et al. 2017). Best for general
use. Single-step, allows weak exogeneity.{p_end}

{p 12 16 2}
{bf:feg} — Fourier Engle-Granger. Two-step residual-based test. Simple and
familiar to practitioners.{p_end}

{p 12 16 2}
{bf:feg2} — Modified FEG. Recommended over FEG in all cases. Controls for
common factor restriction.{p_end}

{p 12 16 2}
{bf:tsong} — Null of cointegration (KPSS-type). Reverses hypothesis direction.
Use for confirmation.{p_end}

{p 12 16 2}
{bf:all} — Runs all four tests sequentially for comprehensive analysis.{p_end}

{dlgtab:Model Specification}

{phang}
{opt model(constant)} includes only intercept + Fourier terms in the
deterministic component. Use when the underlying equilibrium has no trend.

{phang}
{opt model(trend)} includes intercept, linear trend, and Fourier terms. Use when
variables exhibit trending behavior in levels.

{phang}
{opt maxfreq(#)} maximum single Fourier frequency k. The optimal k* is selected
by minimizing SSR across k = 1, ..., maxfreq. Default is 5, but papers
recommend k <= 3 for most applications since low frequencies capture breaks
while high frequencies may capture noise.

{phang}
{opt maxlag(#)} maximum lag length for the grid search (FADL) or
general-to-specific (FEG/FEG2). Default:

{p 12 16 2}
FADL: 6 (matching WinRATS code){p_end}
{p 12 16 2}
FEG/FEG2: int(12*(T/100)^0.25){p_end}

{phang}
{opt criterion(aic|bic)} information criterion for lag selection. AIC tends to
select more lags (better size in finite samples); BIC tends to select fewer lags
(more parsimonious).

{phang}
{opt cumfreq} uses cumulative frequencies q = 1, ..., maxfreq instead of a
single frequency. Each q includes ALL frequencies from 1 to q:

{p 12 16 2}
d(t) = c + g1*sin(2{c pi}t/T) + g2*cos(2{c pi}t/T) + g3*sin(4{c pi}t/T) +
g4*cos(4{c pi}t/T) + ...{p_end}

{pstd}
Cumulative frequencies can approximate more complex break patterns but consume
degrees of freedom. Papers recommend q <= 2 in most cases.

{phang}
{opt dols(#)} number of leads and lags in DOLS estimation for the Tsong test.
Set to 0 for automatic AIC-based selection (default). Typical values: 1-4.

{phang}
{opt graph} produces diagnostic graphs showing the Fourier deterministic fit
overlaid on the dependent variable, plus residual plots.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:Fourier approximation.} A key result from approximation theory (Gallant,
1981) states that a finite number of Fourier frequencies can closely approximate
any integrable function. The deterministic component is:

{p 8 8 2}
d(t) = c + [gamma*t] + sum_{j=1}^{q} [a_j*sin(2{c pi}j*t/T) +
b_j*cos(2{c pi}j*t/T)]

{pstd}
where T is the sample size and q is the number of cumulative frequencies. Even
a single frequency (q = 1) can capture a wide variety of smooth break patterns.

{pstd}
{bf:Frequency selection.} The optimal frequency k* is chosen by minimizing the
sum of squared residuals (SSR) from the estimation equation. This is equivalent
to maximizing the fit of the Fourier component and is the approach recommended
in all three papers.

{pstd}
{bf:Single vs. cumulative frequencies.} Use single frequency for simple break
patterns (one smooth shift). Use cumulative when breaks are complex or
multiple. Start with single frequency and only switch to cumulative if results
are sensitive.


{marker critvals}{...}
{title:Critical Values}

{pstd}
{bf:FADL and FEG critical values} (Banerjee et al. 2017, Tables 1-2):

{p 8 8 2}
Depend on: {it:n} (number of regressors), {it:k} (frequency), {it:T} (sample
size).{break}
Available for: n = 1-3, k = 1-5, T = 100, 500, 2500.{break}
Interpolated for intermediate T values.{break}
Lower-tail test: reject H0 if t-stat < critical value.

{pstd}
{bf:FEG2 critical values} (Banerjee & Lee, Tables 1a-1d):

{p 8 8 2}
Depend on: {it:n}, {it:k}, {it:T}, AND {it:rho-squared}.{break}
Available for: rho-sq = 0.1, 0.2, ..., 1.0.{break}
Lower-tail test: reject H0 if t-stat < critical value.{break}
When rho-sq is close to 1, FEG2 CVs approach FEG CVs.

{pstd}
{bf:Tsong critical values} (Tsong et al. 2016, Table 1):

{p 8 8 2}
Depend on: {it:p} (number of regressors), {it:k} (frequency), {it:m} (0 =
constant, 1 = constant + trend).{break}
{bf:Upper-tail test}: reject H0 if statistic > critical value.{break}
Available for: p = 1-4, k = 1-3.

{pstd}
{bf:F-test critical values} for Fourier component significance:

{p 8 8 2}
m = 0: 10% = 3.352, 5% = 4.066, 1% = 5.774{break}
m = 1: 10% = 3.306, 5% = 4.019, 1% = 5.860


{marker interpretation}{...}
{title:Interpretation Guide}

{pstd}
{bf:Case 1: FADL/FEG/FEG2 reject, Tsong does not reject}

{p 8 8 2}
{bf:Strong evidence of cointegration with Fourier breaks.} Both the no-coint
null (FADL/FEG/FEG2) and the coint null (Tsong) point in the same direction.
This is the ideal confirmatory scenario.

{pstd}
{bf:Case 2: FADL/FEG/FEG2 reject, Tsong also rejects}

{p 8 8 2}
{bf:Contradictory.} This can occur with small samples or misspecification. Check
model specification, try different frequencies, or increase sample size. The
FADL test is generally more reliable due to its single-step nature.

{pstd}
{bf:Case 3: FADL/FEG/FEG2 do not reject, Tsong rejects}

{p 8 8 2}
{bf:Evidence against cointegration.} Both directions suggest no long-run
equilibrium. Consider whether the variables are even I(1) — run unit root tests
first.

{pstd}
{bf:Case 4: None reject}

{p 8 8 2}
{bf:Inconclusive.} Failure to reject H0 in both directions. The tests may lack
power. Consider larger samples, different model specifications, or the
possibility that the relationship is genuinely ambiguous.

{pstd}
{bf:Interpreting the optimal frequency k*:}

{p 8 8 2}
k* = 1: One smooth, gradual break over the sample period.{break}
k* = 2: Two cycles or a U-shaped shift.{break}
k* = 3+: Complex break patterns. Be cautious — high frequencies may be
capturing noise rather than genuine structural change.

{pstd}
{bf:Interpreting rho-squared (FEG2):}

{p 8 8 2}
rho-sq near 0: Variance reduction from Dx augmentation is large. FEG2 is much
more powerful than FEG.{break}
rho-sq near 1: Little variance reduction. FEG2 and FEG have similar power. CFR
holds approximately.

{pstd}
{bf:Interpreting the Fourier F-test (Tsong):}

{p 8 8 2}
F significant: Fourier breaks are present. Use Tsong/FADL/FEG tests.{break}
F not significant: No evidence of Fourier breaks. Consider using standard Shin
(1994) or Engle-Granger tests instead.


{marker requirements}{...}
{title:Requirements and Constraints}

{dlgtab:Data Requirements}

{p 8 8 2}
1. Data must be {cmd:tsset} (time-series declared).{break}
2. All variables must be I(1). Run {cmd:dfuller} or {cmd:pperron} first.{break}
3. No gaps in the time series (balanced panel).{break}
4. Stata 14.0 or higher required.

{dlgtab:FADL Test Constraints}

{p 8 8 2}
Regressors (n): 1 to 3. Critical values available for n = 1, 2, 3.{break}
Frequency (k): 1 to 5.{break}
Sample size (T): minimum 50 recommended, T >= 100 for reliable inference.{break}
Critical values interpolated between T = 100 and T = 500.{break}
Lag search: Dy and each Dx searched independently (1 to maxlag).

{dlgtab:FEG Test Constraints}

{p 8 8 2}
Regressors (n): 1 to 3 (uses FADL critical values).{break}
Frequency (k): 1 to 5.{break}
Sample size (T): minimum 50, T >= 100 recommended.{break}
Lag selection: general-to-specific (drops last lag if |t| < 1.645).{break}
Note: Two-step procedure; requires super-consistent first stage.

{dlgtab:FEG2 Test Constraints}

{p 8 8 2}
Regressors (n): 1 to 2 only (critical values limited to n = 1, 2).{break}
Frequency (k): 1 to 5.{break}
Sample size (T): minimum 50, T >= 100 recommended.{break}
Additional parameter: rho-sq (estimated, range 0.1 to 1.0).{break}
Note: Requires at least 2 variables total (depvar + 1 regressor).

{dlgtab:Tsong Test Constraints}

{p 8 8 2}
Regressors (p): 1 to 4. Critical values for p = 1, 2, 3, 4.{break}
Frequency (k): 1 to 3 only (critical values limited).{break}
Sample size (T): minimum 50 recommended; DOLS leads/lags consume observations.{break}
DOLS lags: auto-selected or user-specified via {opt dols(#)}.{break}
Bandwidth: Bartlett kernel with bw = int(T^{1/3}).{break}
Note: Upper-tail test (large statistic rejects cointegration).

{dlgtab:Summary Table}

{col 5}{bf:Test}{col 18}{bf:Max n}{col 28}{bf:Max k}{col 38}{bf:Min T}{col 50}{bf:Null}
{col 5}{hline 60}
{col 5}FADL{col 18}3{col 28}5{col 38}50{col 50}No cointegration
{col 5}FEG{col 18}3{col 28}5{col 38}50{col 50}No cointegration
{col 5}FEG2{col 18}2{col 28}5{col 38}50{col 50}No cointegration
{col 5}Tsong{col 18}4{col 28}3{col 38}50{col 50}Cointegration
{col 5}{hline 60}


{marker warnings}{...}
{title:Warnings and Practical Notes}

{pstd}
{bf:WARNING 1: Pre-test for unit roots.}

{p 8 8 2}
All cointegration tests require that the variables are I(1) (integrated of
order one). If variables are I(0) or I(2), the tests are invalid. Run
{cmd:dfuller} or {cmd:pperron} on each variable before using {cmd:fcoint}.

{pstd}
{bf:WARNING 2: Tsong test has reversed hypotheses.}

{p 8 8 2}
The Tsong test has H0: cointegration, unlike FADL/FEG/FEG2 which have H0: no
cointegration. A large Tsong statistic {bf:rejects} cointegration. Do not
confuse the direction.

{pstd}
{bf:WARNING 3: Small sample sizes.}

{p 8 8 2}
With T < 100, the tests may have poor size properties, especially with many
frequencies or lags. The papers recommend T >= 100 for reliable inference. With
T < 50, results should be interpreted with extreme caution.

{pstd}
{bf:WARNING 4: Number of regressors.}

{p 8 8 2}
Critical values are provided for n = 1-3 regressors (FADL/FEG) and p = 1-4
(Tsong). If you have more regressors, the program uses the closest available
critical values, but results may be less accurate.

{pstd}
{bf:WARNING 5: High frequencies.}

{p 8 8 2}
The papers strongly recommend keeping the frequency low (k <= 3 for most
applications). High frequencies (k = 4, 5) consume degrees of freedom and may
capture noise rather than genuine structural breaks. Becker et al. (2006)
argue that even k = 1 is sufficient for most economic applications.

{pstd}
{bf:WARNING 6: Cumulative frequencies.}

{p 8 8 2}
With multiple cumulative frequencies, the number of extra parameters grows
quickly (2q extra parameters). Use q <= 2 in most cases unless you have a
very large sample.

{pstd}
{bf:NOTE 1: No estimation of break dates.}

{p 8 8 2}
The Fourier approach is designed to control for breaks, not to estimate them.
If you need break date estimates, use conventional structural break tests (e.g.,
{cmd:estat sbsingle}, Bai-Perron tests).

{pstd}
{bf:NOTE 2: FADL vs FEG.}

{p 8 8 2}
The FADL test is generally preferred over FEG because: (1) it does not require
super-consistent estimation of the long-run equation; (2) it allows for weak
exogeneity; (3) it has better finite-sample properties.

{pstd}
{bf:NOTE 3: Standard errors.}

{p 8 8 2}
The test statistics are non-standard — do not use conventional p-values. Only
compare with the tabulated critical values.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic FADL test}

{phang2}{cmd:. tsset time, monthly}{p_end}
{phang2}{cmd:. fcoint y x1 x2, test(fadl)}{p_end}

{pstd}
{bf:Example 2: FADL with trend and BIC}

{phang2}{cmd:. fcoint y x1 x2, test(fadl) model(trend) criterion(bic)}{p_end}

{pstd}
{bf:Example 3: FADL with cumulative frequencies and graph}

{phang2}{cmd:. fcoint y x1 x2, test(fadl) cumfreq maxfreq(3) graph}{p_end}

{pstd}
{bf:Example 4: FEG2 test (recommended over FEG)}

{phang2}{cmd:. fcoint y x1, test(feg2)}{p_end}

{pstd}
{bf:Example 5: Tsong test (confirms cointegration)}

{phang2}{cmd:. fcoint y x1 x2, test(tsong)}{p_end}

{pstd}
{bf:Example 6: Comprehensive analysis — all tests with graphs}

{phang2}{cmd:. fcoint y x1 x2, test(all) graph}{p_end}

{pstd}
{bf:Example 7: Recommended workflow}

{p 8 8 2}
Step 1: Test for unit roots{break}
{cmd:dfuller y, lags(4)}{break}
{cmd:dfuller x1, lags(4)}{break}
{cmd:dfuller x2, lags(4)}{p_end}

{p 8 8 2}
Step 2: Test for cointegration (H0: no coint){break}
{cmd:fcoint y x1 x2, test(fadl) graph}{break}
{cmd:fcoint y x1 x2, test(feg2)}{p_end}

{p 8 8 2}
Step 3: Confirm (H0: coint){break}
{cmd:fcoint y x1 x2, test(tsong)}{p_end}

{p 8 8 2}
Step 4: Check robustness{break}
{cmd:fcoint y x1 x2, test(fadl) model(trend)}{break}
{cmd:fcoint y x1 x2, test(fadl) criterion(bic)}{break}
{cmd:fcoint y x1 x2, test(fadl) cumfreq}{p_end}


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:fcoint} with {bf:test(fadl)} stores in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(tstat)}}FADL t-statistic (t^F_ADL){p_end}
{synopt:{cmd:r(delta)}}estimated error-correction coefficient{p_end}
{synopt:{cmd:r(se_delta)}}standard error of delta{p_end}
{synopt:{cmd:r(frequency)}}optimal frequency k*{p_end}
{synopt:{cmd:r(ssr)}}sum of squared residuals at optimum{p_end}
{synopt:{cmd:r(nobs)}}number of observations used{p_end}
{synopt:{cmd:r(lag_dy)}}optimal Dy lag length{p_end}
{synopt:{cmd:r(lag_dx)}}optimal Dx lag length{p_end}
{synopt:{cmd:r(eg_tstat)}}companion Fourier EG t-statistic{p_end}
{synopt:{cmd:r(eg_lag)}}companion EG optimal lag{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}

{p2col 5 22 26 2: Locals}{p_end}
{synopt:{cmd:r(test)}}"fadl"{p_end}
{synopt:{cmd:r(model)}}model specification{p_end}
{synopt:{cmd:r(criterion)}}information criterion used{p_end}

{pstd}
{cmd:fcoint} with {bf:test(feg)} or {bf:test(feg2)}:

{synopt:{cmd:r(tstat)}}FEG/FEG2 t-statistic{p_end}
{synopt:{cmd:r(delta)}}ADF coefficient on mu_hat_{t-1}{p_end}
{synopt:{cmd:r(se_delta)}}standard error{p_end}
{synopt:{cmd:r(frequency)}}optimal frequency k*{p_end}
{synopt:{cmd:r(nobs)}}observations{p_end}
{synopt:{cmd:r(lag)}}ADF lag length{p_end}
{synopt:{cmd:r(rho2)}}estimated rho-squared (FEG2 only){p_end}
{synopt:{cmd:r(cv1) r(cv5) r(cv10)}}critical values{p_end}

{pstd}
{cmd:fcoint} with {bf:test(tsong)}:

{synopt:{cmd:r(CI_stat)}}KPSS-type cointegration statistic{p_end}
{synopt:{cmd:r(F_stat)}}F-test for Fourier component{p_end}
{synopt:{cmd:r(omega2)}}estimated long-run variance{p_end}
{synopt:{cmd:r(frequency)}}optimal frequency k*{p_end}
{synopt:{cmd:r(nobs)}}observations{p_end}
{synopt:{cmd:r(dolslags)}}DOLS leads/lags used{p_end}
{synopt:{cmd:r(ci_cv1) r(ci_cv5) r(ci_cv10)}}CI critical values{p_end}
{synopt:{cmd:r(f_cv1) r(f_cv5) r(f_cv10)}}F-test critical values{p_end}


{marker graphs}{...}
{title:Graphs}

{pstd}
When the {opt graph} option is specified, {cmd:fcoint} produces diagnostic
graphs:

{pstd}
{bf:FADL/FEG tests:}

{p 8 8 2}
Panel 1: Dependent variable with Fourier deterministic fit overlaid.{break}
Panel 2: Residuals from the long-run equation (should look stationary if
cointegrated).{break}
Panel 3: Fourier component isolated (showing the smooth break pattern).

{pstd}
{bf:Tsong test:}

{p 8 8 2}
Panel 1: DOLS fit vs actual.{break}
Panel 2: CUSUM of DOLS residuals (should stay within bounds if cointegrated).

{pstd}
{bf:How to read the graphs:}

{p 8 8 2}
If the Fourier fit closely tracks the dependent variable's long-run movement
(ignoring short-run noise), the Fourier terms are capturing genuine structural
shifts. If the residuals look stationary (mean-reverting), this supports
cointegration.


{marker references}{...}
{title:References}

{pstd}
Banerjee, P., V. Arcabic, and H. Lee (2017).
{it:Fourier ADL cointegration test to approximate smooth breaks with new evidence from Crude Oil Market.}
Economic Modelling 67: 114-124.

{pstd}
Banerjee, P. and H. Lee.
{it:Residual-based cointegration tests for smooth structural breaks.}
Working Paper.

{pstd}
Tsong, C-C., C-F. Lee, L-J. Tsai, and T-C. Hu (2016).
{it:The Fourier approximation and testing for the null of cointegration.}
Empirical Economics 51: 1085-1113.

{pstd}
Enders, W. and J. Lee (2012).
{it:A unit root test using a Fourier series to approximate smooth breaks.}
Oxford Bulletin of Economics and Statistics 74: 574-599.

{pstd}
Becker, R., W. Enders, and J. Lee (2006).
{it:A stationarity test in the presence of an unknown number of smooth breaks.}
Journal of Time Series Analysis 27: 381-409.

{pstd}
Shin, Y. (1994).
{it:A residual-based test of the null of cointegration against the alternative of no cointegration.}
Econometric Theory 10: 91-115.

{pstd}
Banerjee, A., J. Dolado, and R. Mestre (1998).
{it:Error-correction mechanism tests for cointegration in a single-equation framework.}
Journal of Time Series Analysis 19: 267-283.

{pstd}
Saikkonen, P. (1991).
{it:Asymptotically efficient estimation of cointegration regressions.}
Econometric Theory 7: 1-21.

{pstd}
Gallant, A.R. (1981).
{it:On the bias in flexible functional forms and an essentially unbiased form.}
Journal of Econometrics 15: 211-245.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com

{pstd}
Translated from WinRATS code by Banerjee, Arcabic & Lee.


{title:Also see}

{p 4 14 2}
Online: {helpb tsset}, {helpb dfuller}, {helpb pperron}, {helpb vec},
{helpb estat sbsingle}
{p_end}
