{smcl}
{* *! version 1.2.0  18feb2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] ardl" "help ardl"}{...}
{vieweralsosee "[R] nardl" "help nardl"}{...}
{viewerjumpto "Syntax" "fbnardl##syntax"}{...}
{viewerjumpto "Description" "fbnardl##description"}{...}
{viewerjumpto "Methodology" "fbnardl##methodology"}{...}
{viewerjumpto "Options" "fbnardl##options"}{...}
{viewerjumpto "Output tables" "fbnardl##tables"}{...}
{viewerjumpto "Graphs" "fbnardl##graphs"}{...}
{viewerjumpto "Stored results" "fbnardl##results"}{...}
{viewerjumpto "Examples" "fbnardl##examples"}{...}
{viewerjumpto "Interpretation" "fbnardl##interpretation"}{...}
{viewerjumpto "References" "fbnardl##references"}{...}
{viewerjumpto "Author" "fbnardl##author"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:fbnardl} {hline 2}}Fourier Bootstrap Nonlinear Autoregressive Distributed Lag Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:fbnardl}
{depvar}
[{it:control_vars}]
{ifin}{cmd:,}
{cmdab:dec:ompose(}{varlist}{cmd:)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt dec:ompose(varlist)}}variables to decompose into +/- partial sums; {bf:required}{p_end}
{synopt:{opt type(string)}}model type: {bf:fnardl} (default) or {bf:fbnardl}{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag order for grid search; default {bf:4}{p_end}
{synopt:{opt maxk(#)}}maximum Fourier frequency; default {bf:3}{p_end}
{synopt:{opt ic(string)}}information criterion: {bf:aic} (default) or {bf:bic}{p_end}
{synopt:{opt nof:ourier}}pure NARDL without Fourier terms{p_end}

{syntab:Bootstrap ({cmd:type(fbnardl)} only)}
{synopt:{opt reps(#)}}bootstrap replications; default {bf:999}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synopt:{opt hor:izon(#)}}multiplier/persistence horizon; default {bf:20}{p_end}
{synopt:{opt nodiag}}suppress diagnostics (Table 6){p_end}
{synopt:{opt nodyn:mult}}suppress dynamic multipliers and graphs{p_end}
{synopt:{opt noadv:anced}}suppress advanced analyses (Tables 7-9){p_end}
{synopt:{opt not:able}}suppress regression table (Table 2){p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:fbnardl}; see {helpb tsset}.
{p_end}

{p 4 6 2}
{it:depvar} and {it:control_vars} may contain time-series operators; see {help tsvarlist}.
{p_end}

{p 4 6 2}
Variables in {opt decompose()} are split into positive/negative partial sums.
All other variables in {it:varlist} enter as non-decomposed controls.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fbnardl} estimates a {bf:Fourier Nonlinear Autoregressive Distributed Lag}
(FNARDL) model that combines three methodological advances:
{p_end}

{phang}
{bf:1. Nonlinear ARDL (NARDL):} Decomposes selected regressors into positive and
negative partial sums to capture asymmetric short-run and long-run effects
(Shin, Yu & Greenwood-Nimmo, 2014).
{p_end}

{phang}
{bf:2. Fourier approximation:} Incorporates low-frequency trigonometric terms to
capture smooth structural breaks of unknown form (Yilanci, Bozoklu & Gorus, 2020;
Enders & Lee, 2012).
{p_end}

{phang}
{bf:3. Bootstrap cointegration testing:} Optionally uses a parametric bootstrap
procedure for computing finite-sample critical values (Bertelli, Vacca & Zoia,
2022; McNown, Sam & Goh, 2018).
{p_end}

{pstd}
The command performs a two-step model selection (Yilanci et al. 2020), produces
up to 9 output tables, and generates publication-quality graphs including
a k* selection plot, dynamic multipliers, persistence profiles, and asymmetric
adjustment comparisons.
{p_end}


{marker methodology}{...}
{title:Methodology}

{pstd}
{ul:The FNARDL Model Equation}
{p_end}

{pstd}
The ARDL(p, q, r) error correction model estimated by {cmd:fbnardl} is:
{p_end}

{p 8 8 2}
{it:d.y_t = c + SUM(j=1..p) phi_j * d.y_{t-j}}
{p_end}
{p 12 12 2}
{it:+ SUM(j=0..q) [theta+_j * d.x+_{t-j} + theta-_j * d.x-_{t-j}]}
{p_end}
{p 12 12 2}
{it:+ SUM(j=0..r) delta_j * d.z_{t-j}}
{p_end}
{p 12 12 2}
{it:+ alpha * y_{t-1} + beta+ * x+_{t-1} + beta- * x-_{t-1} + gamma * z_{t-1}}
{p_end}
{p 12 12 2}
{it:+ lambda1 * sin(2*pi*k*t/T) + lambda2 * cos(2*pi*k*t/T) + epsilon_t}
{p_end}

{pstd}
where:
{p_end}

{phang2}
{cmd:d.y_t} = first difference of the dependent variable
{p_end}

{phang2}
{cmd:x+_t, x-_t} = positive and negative partial sums of decomposed variable(s):
x+_t = SUM(i=1..t) max(d.x_i, 0) and x-_t = SUM(i=1..t) min(d.x_i, 0)
{p_end}

{phang2}
{cmd:z_t} = non-decomposed control variable(s)
{p_end}

{phang2}
{cmd:alpha} = error correction (ECM) coefficient (speed of adjustment)
{p_end}

{phang2}
{cmd:beta+, beta-} = long-run level coefficients (decomposed)
{p_end}

{phang2}
{cmd:gamma} = long-run level coefficient (controls)
{p_end}

{phang2}
{cmd:sin(.), cos(.)} = Fourier terms to capture structural breaks
{p_end}

{phang2}
{cmd:k*} = optimal Fourier frequency (selected by minimum SSR)
{p_end}

{pstd}
{ul:Partial Sum Decomposition}
{p_end}

{pstd}
Following Shin, Yu & Greenwood-Nimmo (2014), each variable in {opt decompose()}
is split into two new variables:
{p_end}

{phang2}
{cmd:var_pos} = SUM(i=1..t) max(d.var_i, 0) {hline 2} cumulative positive changes
{p_end}

{phang2}
{cmd:var_neg} = SUM(i=1..t) min(d.var_i, 0) {hline 2} cumulative negative changes
{p_end}

{pstd}
This allows positive and negative changes to have different impacts on the
dependent variable in both the short run and the long run.
{p_end}

{pstd}
{ul:Fourier Approximation}
{p_end}

{pstd}
Following Enders & Lee (2012) and Yilanci et al. (2020), a pair of trigonometric
terms {hline 2} sin(2*pi*k*t/T) and cos(2*pi*k*t/T) {hline 2} are included to capture
smooth structural breaks without pre-specifying break dates. The frequency k*
controls the oscillation pattern:
{p_end}

{phang2}
Small k* (< 1): slow, gradual structural shifts
{p_end}

{phang2}
k* = 1: one full oscillation (single structural break)
{p_end}

{phang2}
k* > 1: multiple breaks or higher-frequency regime changes
{p_end}

{pstd}
Use {opt nofourier} to exclude Fourier terms and estimate a pure NARDL.
{p_end}

{pstd}
{ul:Two-Step Model Selection (Yilanci et al. 2020)}
{p_end}

{pstd}
{bf:Step 1 {hline 2} Select k* by minimum SSR:}
For each candidate k* in {0.1, 0.2, ..., maxk}, a maximal ARDL model
(p=maxlag, q=maxlag, r=maxlag) is estimated and the SSR is recorded.
The k* with the lowest SSR is selected. A graph ({bf:kstar_selection.png})
visualizes the SSR across all candidate frequencies.
{p_end}

{pstd}
{bf:Step 2 {hline 2} Select lags (p,q,r) by AIC/BIC with fixed k*:}
With k* fixed from Step 1, an exhaustive grid search over all lag combinations:
{p_end}

{phang2}
p = {1, ..., maxlag} {hline 2} lags of d.y
{p_end}

{phang2}
q_i = {0, ..., maxlag} {hline 2} lags of each decomposed variable's partial sums
{p_end}

{phang2}
r_j = {0, ..., maxlag} {hline 2} lags of each control variable
{p_end}

{pstd}
The combination with the lowest AIC (default) or BIC is selected.
Each variable may have a different optimal lag order.
{p_end}

{pstd}
{ul:Long-Run Multipliers}
{p_end}

{pstd}
For decomposed variables:
LR+ = -beta+ / alpha  and  LR- = -beta- / alpha
{p_end}

{pstd}
For non-decomposed controls:
LR = -gamma / alpha
{p_end}

{pstd}
Standard errors are computed via the delta method ({cmd:nlcom}).
{p_end}

{pstd}
{ul:Dynamic Multipliers}
{p_end}

{pstd}
Dynamic multipliers trace the time path of a unit shock at each horizon h:
{p_end}

{p 8 8 2}
m_h = theta_h + SUM(j=1..min(h,p)) phi_j * m_{h-j}
{p_end}

{pstd}
Cumulative multipliers are the running sum. For decomposed variables, separate
positive and negative paths are shown; for controls, a single path.
{p_end}

{pstd}
{ul:Cointegration Testing}
{p_end}

{pstd}
{bf:type(fnardl)} {hline 2} PSS bounds test (Pesaran, Shin & Smith, 2001) with
Kripfganz & Schneider (2020) critical values. Three statistics:
F_overall, t_dependent, and F_independent.
{p_end}

{pstd}
{bf:type(fbnardl)} {hline 2} Parametric bootstrap (Bertelli et al. 2022).
Simulates the null distribution of no cointegration.
Reports critical values at 1%, 2.5%, 5%, 10% plus bootstrap p-values.
{p_end}

{pstd}
{ul:Diagnostic Tests}
{p_end}

{phang2}Normality: Jarque-Bera, Shapiro-Wilk, Shapiro-Francia{p_end}
{phang2}Serial correlation: Breusch-Godfrey LM (1-4 lags), Durbin-Watson{p_end}
{phang2}Heteroskedasticity: Breusch-Pagan, White, ARCH LM{p_end}
{phang2}Functional form: Ramsey RESET{p_end}
{phang2}Stability: CUSUM and CUSUM-squared at 5%{p_end}

{pstd}
{ul:Half-Life and Persistence Profile}
{p_end}

{pstd}
ECM half-life = -ln(2) / ln(1 + alpha). The persistence profile
(Pesaran & Shin, 1996) traces the proportion of disequilibrium remaining
at each horizon after a system-wide shock.
{p_end}

{pstd}
{ul:Asymmetric Adjustment Speed}
{p_end}

{pstd}
For each decomposed variable, compares how positive vs. negative shocks
converge to their long-run equilibria. Metrics: impact multiplier, effective
long-run, half-life, 90% adjustment time, and overshoot detection.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt decompose(varlist)} specifies variables to decompose into positive/negative
partial sums. The positive sum captures cumulative positive changes; the negative
sum captures cumulative negative changes. Multiple variables allowed; each gets
its own lag order.
{p_end}

{phang}
{opt type(string)} sets the cointegration test type.
{cmd:type(fnardl)} = PSS bounds test with Kripfganz & Schneider critical values (default).
{cmd:type(fbnardl)} = parametric bootstrap critical values (Bertelli et al. 2022).
{p_end}

{phang}
{opt maxlag(#)} maximum lag order for the grid search over p, q, and r.
Default is 4. Higher values increase flexibility but also computation time.
{p_end}

{phang}
{opt maxk(#)} maximum Fourier frequency. Default is 3. The search grid is
k* = {0.1, 0.2, ..., maxk}. Small k* captures slow shifts; large k* captures
frequent changes.
{p_end}

{phang}
{opt ic(string)} information criterion for lag selection (Step 2).
{cmd:ic(aic)} = Akaike (default, tends to larger models).
{cmd:ic(bic)} = Bayesian (favors parsimony).
{p_end}

{phang}
{opt nofourier} estimates pure NARDL without Fourier terms. Compare with
the Fourier specification to assess the importance of structural breaks.
{p_end}

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} number of bootstrap replications for {cmd:type(fbnardl)}.
Default 999. Use 99 for exploratory; 999-1999 for final; 4999+ for publication.
{p_end}

{dlgtab:Reporting}

{phang}
{opt level(#)} confidence level. Default is {cmd:c(level)}.
{p_end}

{phang}
{opt horizon(#)} dynamic multiplier and persistence profile horizon.
Default 20. Use 30-50 if the ECM coefficient is small (slow adjustment).
{p_end}

{phang}
{opt nodiag} suppresses the diagnostic test table (Table 6).
{p_end}

{phang}
{opt nodynmult} suppresses dynamic multiplier computation and all graphs.
{p_end}

{phang}
{opt noadvanced} suppresses Tables 7-9 (half-life, persistence, Fourier test,
asymmetric adjustment).
{p_end}

{phang}
{opt notable} suppresses the full regression coefficient table (Table 2).
{p_end}


{marker tables}{...}
{title:Output tables}

{pstd}
{cmd:fbnardl} produces up to 9 tables:
{p_end}

{dlgtab:Table 1 - Model Selection}

{pstd}
Reports the selected model specification and fit statistics:
{p_end}

{phang2}
{bf:Lag orders:} p (dependent variable), q_1, ..., q_d (each decomposed
variable), r_1, ..., r_c (each control variable).
Each variable may have a different optimal lag.
{p_end}

{phang2}
{bf:Fourier frequency:} k* selected in Step 1 (minimum SSR).
Shows 0 when {opt nofourier} is specified.
{p_end}

{phang2}
{bf:Fit statistics:} Information criterion value (AIC or BIC), AIC, BIC,
log-likelihood, number of observations, R-squared, adjusted R-squared,
and the overall F-statistic with its p-value.
{p_end}

{phang2}
{bf:Grid search summary:} Number of lag combinations evaluated and the
number of Fourier frequencies tested.
{p_end}

{dlgtab:Table 2 - Estimation Results}

{pstd}
Full OLS coefficient table with standard errors, t-statistics, p-values,
and significance stars. Organized into three panels:
{p_end}

{phang2}
{bf:Panel A {hline 2} Short-Run Dynamics:}
Lagged differences of the dependent variable (D.y_{t-1}, ..., D.y_{t-p});
lagged differences of positive/negative partial sums for each decomposed
variable (D.x+_{t-j}, D.x-_{t-j} for j = 0, ..., q_i);
lagged differences of control variables (D.z_{t-j} for j = 0, ..., r_j).
{p_end}

{phang2}
{bf:Panel B {hline 2} Long-Run (ECM Level) Coefficients:}
Error correction term (alpha = coefficient on L.depvar, expected negative
for stable equilibrium); level terms for decomposed variables
(L.var_pos = beta+, L.var_neg = beta-); level terms for controls
(L.var = gamma).
{p_end}

{phang2}
{bf:Panel C {hline 2} Fourier Terms and Constant:}
Coefficients on sin(2*pi*k*t/T) and cos(2*pi*k*t/T), plus the regression
constant. These terms capture smooth structural breaks.
{p_end}

{dlgtab:Table 3 - Short-Run & Long-Run Multipliers}

{pstd}
{bf:For each decomposed variable:}
{p_end}

{phang2}
SR+ (short-run positive multiplier): sum of contemporaneous and lagged
D-coefficients for the positive partial sum.
{p_end}

{phang2}
SR- (short-run negative multiplier): sum of contemporaneous and lagged
D-coefficients for the negative partial sum.
{p_end}

{phang2}
LR+ (long-run positive multiplier): -beta+ / alpha, computed via
the delta method ({cmd:nlcom}) with standard errors, t-statistics,
p-values, and confidence intervals.
{p_end}

{phang2}
LR- (long-run negative multiplier): -beta- / alpha, same method.
{p_end}

{phang2}
Asymmetry ratios: |SR+/SR-| and |LR+/LR-|. Values close to 1 indicate
symmetry. Values far from 1 indicate meaningful asymmetry between
positive and negative shocks.
{p_end}

{pstd}
{bf:For each non-decomposed control variable:}
{p_end}

{phang2}
SR (short-run multiplier): sum of contemporaneous and lagged D-coefficients,
with Std.Err., t-stat, and p-value.
{p_end}

{phang2}
LR (long-run multiplier): -gamma / alpha, with delta-method inference.
{p_end}

{dlgtab:Table 4 - Wald Tests for Asymmetry}

{pstd}
For each decomposed variable, two formal tests of asymmetry:
{p_end}

{phang2}
{bf:Short-run asymmetry:} F-test of H0: theta+_0 = theta-_0.{break}
Tests whether the contemporaneous (lag-0) impacts of positive and negative
shocks are equal. A significant result (p < 0.05) means the immediate
response to a positive shock differs from a negative shock.
{p_end}

{phang2}
{bf:Long-run asymmetry:} Chi-squared test of H0: LR+ = LR- (via
{cmd:testnl}).{break}
Tests whether the total equilibrium effects differ. This is the key test
for the NARDL framework. A significant result confirms that positive and
negative changes have permanently different long-run effects.
{p_end}

{dlgtab:Table 5 - Cointegration Test}

{pstd}
Three test statistics following McNown, Sam & Goh (2018):
{p_end}

{phang2}
{bf:F_overall:} Joint significance of all lagged level variables
(alpha = beta+ = beta- = gamma = 0). The main Pesaran et al. (2001)
bounds test statistic.
{p_end}

{phang2}
{bf:t_dependent:} t-statistic on the lagged dependent variable (L.depvar).
Tests H0: alpha = 0. Must be significant and negative for valid ECM.
{p_end}

{phang2}
{bf:F_independent:} Joint significance of lagged independent level
variables only (beta+ = beta- = gamma = 0). Excludes alpha.
{p_end}

{pstd}
{cmd:type(fnardl)}: Reports PSS bounds test critical values from
Kripfganz & Schneider (2020) response surfaces at 10%, 5%, and 1%
significance levels. Decision column shows "Reject H0" (cointegration),
"Fail to reject" (no cointegration), or "Inconclusive" (between bounds).
{p_end}

{pstd}
{cmd:type(fbnardl)}: Reports bootstrap critical values at 1%, 2.5%, 5%, 10%
levels from {opt reps()} replications. Also shows the bootstrap p-value
(proportion of bootstrap statistics exceeding the sample statistic).
Bootstrap inference is preferred for small samples.
{p_end}

{dlgtab:Table 6 - Diagnostic Tests}

{pstd}
Full battery of specification tests:
{p_end}

{phang2}
{bf:Normality:} Jarque-Bera chi-squared test (skewness + kurtosis),
Shapiro-Wilk W test, and Shapiro-Francia W' test. All three test
H0: residuals are normally distributed.
{p_end}

{phang2}
{bf:Serial correlation:} Breusch-Godfrey LM test at lags 1, 2, 3, and 4.
Also reports the Durbin-Watson d statistic. H0: no serial correlation.
Significant results indicate model misspecification or omitted dynamics.
{p_end}

{phang2}
{bf:Heteroskedasticity:} Breusch-Pagan chi-squared test for linear
heteroskedasticity; White's general test (includes cross-products);
ARCH LM test for conditional heteroskedasticity. H0: homoskedastic
errors.
{p_end}

{phang2}
{bf:Functional form:} Ramsey RESET test using powers of fitted values.
H0: no omitted nonlinearity. Significant results suggest the linear
specification is inadequate.
{p_end}

{phang2}
{bf:Stability:} CUSUM and CUSUM-squared tests at 5% significance.
These are recursive residual-based tests for parameter stability.
"Stable" indicates parameters do not change over the sample period.
{p_end}

{dlgtab:Table 7 - Half-Life & Persistence Analysis}

{pstd}
Reports the following based on the ECM coefficient alpha:
{p_end}

{phang2}
{bf:ECM half-life:} -ln(2) / ln(1 + alpha). The number of periods for
half the disequilibrium to be corrected. Example: if alpha = -0.3
(quarterly data), half-life = 1.94 quarters.
{p_end}

{phang2}
{bf:Mean adjustment lag:} -1 / alpha. The average time to adjust.
{p_end}

{phang2}
{bf:99% adjustment time:} -ln(100) / ln(1 + alpha). Periods until
99% of the disequilibrium is corrected.
{p_end}

{phang2}
{bf:Persistence profile table:} Pesaran & Shin (1996) profile showing
the fraction of disequilibrium remaining at horizons h = 0, 1, ..., H.
Decays from 1.0 (full shock) toward 0.0 (full adjustment).
{p_end}

{phang2}
{bf:Persistence profile half-life:} The horizon where the profile
first crosses 0.5.
{p_end}

{dlgtab:Table 8 - Fourier Terms Joint Significance}

{pstd}
F-test of H0: lambda_1 = lambda_2 = 0 (Fourier terms are jointly
insignificant, i.e., no structural break). Reports the F-statistic,
numerator and denominator degrees of freedom, and p-value.
{p_end}

{pstd}
If significant (p < 0.05): the Fourier terms capture meaningful structural
breaks, and the FNARDL specification is preferred.
{p_end}

{pstd}
If insignificant: consider using {opt nofourier} to estimate a standard
NARDL, which is more parsimonious.
{p_end}

{dlgtab:Table 9 - Asymmetric Adjustment Speed}

{pstd}
For each decomposed variable, compares adjustment dynamics of positive vs.
negative shocks:
{p_end}

{phang2}
{bf:Analytical LR multiplier:} From the delta method (Table 3).
{p_end}

{phang2}
{bf:Effective LR:} Where the cumulative dynamic multiplier converges.
May differ from analytical LR if the dynamic path overshoots.
{p_end}

{phang2}
{bf:Impact multiplier (h=0):} Contemporaneous effect of the shock.
{p_end}

{phang2}
{bf:Impact as % of effective LR:} Shows how much of the long-run
effect is realized immediately. Values > 100% indicate overshoot.
{p_end}

{phang2}
{bf:Half-life:} Periods to reach 50% of the effective long-run.
Reported as "Overshoot" when the impact exceeds the long-run.
{p_end}

{phang2}
{bf:90% adjustment time:} Periods to reach 90% of the effective long-run.
{p_end}

{phang2}
{bf:Overshoot flag:} "Yes" if the impact multiplier exceeds the
effective long-run, indicating initial over-reaction followed by
partial reversal.
{p_end}


{marker graphs}{...}
{title:Graphs}

{pstd}
All graphs are saved as PNG files (1200px wide) in the current working
directory. Graphs are also displayed in the Stata graph window using
named windows so they can be recalled.
{p_end}

{dlgtab:Fourier frequency selection}

{phang2}
{bf:kstar_selection.png}: Plots the sum of squared residuals (SSR) from
Step 1 against each candidate Fourier frequency k*. The SSR values are
shown as a connected navy line with circle markers. The optimal k*
(minimum SSR) is highlighted with a large red (cranberry) diamond marker
and a red dashed vertical reference line. The graph title indicates
this is the Yilanci et al. (2020) selection procedure. This graph is
only produced when multiple k* values are tested (not with {opt nofourier}).
{p_end}

{dlgtab:Dynamic multipliers}

{phang2}
{bf:dynmult_{it:var}.png}: Dynamic multiplier paths showing the period-by-period
effect of a unit shock at each horizon h = 0, 1, ..., H. For decomposed
variables, two lines are plotted: positive multiplier path (blue) and
negative multiplier path (red). For non-decomposed controls, a single
navy line shows the total dynamic effect. Includes a zero reference line.
{p_end}

{phang2}
{bf:cummult_{it:var}.png}: Cumulative multiplier paths (running sum of
dynamic multipliers). For decomposed variables, shows positive and
negative cumulative paths with their respective LR+ and LR- horizontal
target lines, allowing visual assessment of convergence speed. For
controls, a single cumulative path with the LR target line.
{p_end}

{dlgtab:Persistence profile}

{phang2}
{bf:persistence_profile.png}: Pesaran & Shin (1996) persistence profile
plotting the proportion of disequilibrium remaining at each horizon h.
Starts at 1.0 and decays toward 0.0. A horizontal dashed reference line
at 0.5 indicates the half-life horizon. The graph shows how quickly the
system returns to long-run equilibrium after a system-wide shock.
{p_end}

{dlgtab:Asymmetric adjustment}

{phang2}
{bf:asymmetric_adjustment_{it:var}.png}: Plots positive and negative shock
adjustment paths as a percentage of their respective effective long-run
equilibria. Includes half-life markers (vertical dashed lines) for each
component and a 100% horizontal reference line (full adjustment).
When both paths are visible, the graph reveals which shock type
(positive or negative) adjusts faster to its long-run target.
{p_end}

{phang2}
{bf:halflife_comparison_{it:var}.png}: Side-by-side bar chart comparing
half-life periods and 90% adjustment times for positive vs. negative
shocks. Provides an at-a-glance visual comparison of adjustment speeds.
This graph is skipped when both positive and negative components
overshoot their long-run targets.
{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fbnardl} stores the following in {cmd:e()}:
{p_end}

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(best_p)}}selected lag p{p_end}
{synopt:{cmd:e(best_q)}}selected lag q (max across decomposed){p_end}
{synopt:{cmd:e(best_kstar)}}selected Fourier frequency k*{p_end}
{synopt:{cmd:e(ic_val)}}IC value at optimal model{p_end}
{synopt:{cmd:e(aic)}}AIC{p_end}
{synopt:{cmd:e(bic)}}BIC{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(F)}}overall F-statistic{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(Fov)}}PSS F_overall{p_end}
{synopt:{cmd:e(t_dep)}}t-statistic on L.depvar{p_end}
{synopt:{cmd:e(Find)}}F-statistic on lagged independents{p_end}
{synopt:{cmd:e(alpha)}}ECM coefficient{p_end}
{synopt:{cmd:e(halflife)}}ECM half-life (periods){p_end}
{synopt:{cmd:e(lr_pos_{it:var})}}positive LR multiplier{p_end}
{synopt:{cmd:e(lr_neg_{it:var})}}negative LR multiplier{p_end}
{synopt:{cmd:e(lr_{it:var})}}LR multiplier (control){p_end}

{p2col 5 28 32 2: Scalars (bootstrap, {cmd:type(fbnardl)} only)}{p_end}
{synopt:{cmd:e(bs_reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(bs_Fov_cv01)}}bootstrap 1% critical value for F_overall{p_end}
{synopt:{cmd:e(bs_Fov_cv025)}}bootstrap 2.5% critical value for F_overall{p_end}
{synopt:{cmd:e(bs_Fov_cv05)}}bootstrap 5% critical value for F_overall{p_end}
{synopt:{cmd:e(bs_Fov_cv10)}}bootstrap 10% critical value for F_overall{p_end}
{synopt:{cmd:e(bs_Fov_pval)}}bootstrap p-value for F_overall{p_end}
{synopt:{cmd:e(bs_t_cv01)}}bootstrap 1% critical value for t_dependent{p_end}
{synopt:{cmd:e(bs_t_cv025)}}bootstrap 2.5% critical value for t_dependent{p_end}
{synopt:{cmd:e(bs_t_cv05)}}bootstrap 5% critical value for t_dependent{p_end}
{synopt:{cmd:e(bs_t_cv10)}}bootstrap 10% critical value for t_dependent{p_end}
{synopt:{cmd:e(bs_t_pval)}}bootstrap p-value for t_dependent{p_end}
{synopt:{cmd:e(bs_Find_cv01)}}bootstrap 1% critical value for F_independent{p_end}
{synopt:{cmd:e(bs_Find_cv025)}}bootstrap 2.5% critical value for F_independent{p_end}
{synopt:{cmd:e(bs_Find_cv05)}}bootstrap 5% critical value for F_independent{p_end}
{synopt:{cmd:e(bs_Find_cv10)}}bootstrap 10% critical value for F_independent{p_end}
{synopt:{cmd:e(bs_Find_pval)}}bootstrap p-value for F_independent{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:fbnardl}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(type)}}{cmd:fnardl} or {cmd:fbnardl}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(decompose)}}decomposed variable name(s){p_end}
{synopt:{cmd:e(controls)}}control variable name(s), if any{p_end}
{synopt:{cmd:e(ic)}}information criterion used (aic or bic){p_end}
{synopt:{cmd:e(model_spec)}}full specification string, e.g., FNARDL(2,0,0) k*=0.1{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector from OLS regression{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of coefficients{p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{ul:Data Setup}
{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen y = 0}{p_end}
{phang2}{cmd:. gen x1 = 0}{p_end}
{phang2}{cmd:. gen x2 = 0}{p_end}
{phang2}{cmd:. gen z1 = 0}{p_end}
{phang2}{cmd:. gen z2 = 0}{p_end}
{phang2}{cmd:. replace x1 = L.x1 + rnormal() if _n > 1}{p_end}
{phang2}{cmd:. replace x2 = L.x2 + rnormal() if _n > 1}{p_end}
{phang2}{cmd:. replace z1 = L.z1 + rnormal() if _n > 1}{p_end}
{phang2}{cmd:. replace z2 = L.z2 + rnormal() if _n > 1}{p_end}
{phang2}{cmd:. replace y = 0.3*L.y + 0.5*x1 - 0.2*x2 + 0.1*z1 - 0.3*z2 + rnormal()}{p_end}

{pstd}
{bf:{ul:Case 1: One decomposed variable + one control (basic)}}
{p_end}

{pstd}
Decompose x1 into positive/negative shocks; z1 enters as a control:
{p_end}

{phang2}{cmd:. fbnardl y z1, decompose(x1) maxlag(4) ic(aic)}{p_end}

{pstd}
This is the most common use case. Produces all 9 tables, k* selection graph,
dynamic multiplier graphs, persistence profile, and asymmetric adjustment graphs.
x1 gets positive/negative multipliers and asymmetry tests. z1 gets a single-path
multiplier.
{p_end}

{pstd}
{bf:{ul:Case 2: One decomposed variable, no controls}}
{p_end}

{pstd}
Bivariate model with only the decomposed variable:
{p_end}

{phang2}{cmd:. fbnardl y, decompose(x1) maxlag(4) ic(aic)}{p_end}

{pstd}
Simpler model. No control variable tables or graphs. Reduces to the original
Shin et al. (2014) NARDL with Fourier terms added.
{p_end}

{pstd}
{bf:{ul:Case 3: Multiple decomposed variables, no controls}}
{p_end}

{pstd}
Both x1 and x2 are decomposed:
{p_end}

{phang2}{cmd:. fbnardl y, decompose(x1 x2) maxlag(4) ic(aic)}{p_end}

{pstd}
Each decomposed variable gets its own: partial sums, multiplier table, asymmetry
tests, dynamic multiplier graphs, and asymmetric adjustment analysis. Each may
have a different optimal lag q.
{p_end}

{pstd}
{bf:{ul:Case 4: Multiple decomposed + multiple controls}}
{p_end}

{pstd}
Full model with x1, x2 decomposed and z1, z2 as controls:
{p_end}

{phang2}{cmd:. fbnardl y z1 z2, decompose(x1 x2) maxlag(4) ic(aic)}{p_end}

{pstd}
The most general case. Each variable has its own optimal lag. Controls get
single-path dynamic multipliers and their own LR estimates.
{p_end}

{pstd}
{bf:{ul:Case 5: Pure NARDL (no Fourier terms)}}
{p_end}

{phang2}{cmd:. fbnardl y z1, decompose(x1) nofourier maxlag(4) ic(aic)}{p_end}

{pstd}
Standard NARDL without structural break approximation. No k* selection graph.
No Table 8 (Fourier significance). Compare AIC/BIC with the Fourier version
to decide which specification is preferred.
{p_end}

{pstd}
{bf:{ul:Case 6: Bootstrap cointegration testing}}
{p_end}

{phang2}{cmd:. fbnardl y z1, decompose(x1) type(fbnardl) reps(999) maxlag(4)}{p_end}

{pstd}
Uses bootstrapped critical values instead of asymptotic PSS bounds.
Table 5 now shows bootstrap CVs at 1%, 2.5%, 5%, 10% plus bootstrap p-values.
Preferred for small samples or when asymptotic bounds may be unreliable.
{p_end}

{pstd}
{bf:{ul:Case 7: BIC model selection with longer horizon}}
{p_end}

{phang2}{cmd:. fbnardl y z1, decompose(x1) ic(bic) maxlag(4) horizon(40)}{p_end}

{pstd}
BIC penalizes complexity more than AIC, selecting more parsimonious models.
horizon(40) extends the dynamic multiplier and persistence profile plots to
40 periods {hline 2} useful when adjustment is slow.
{p_end}

{pstd}
{bf:{ul:Case 8: Quick estimation (suppress extras)}}
{p_end}

{phang2}{cmd:. fbnardl y z1, decompose(x1) nodiag nodynmult noadvanced}{p_end}

{pstd}
Produces only Tables 1-5 and no graphs. Fastest estimation for exploratory work.
{p_end}

{pstd}
{bf:{ul:Case 9: Real-world application}}
{p_end}

{pstd}
GDP growth model testing asymmetric inflation effects with unemployment control:
{p_end}

{phang2}{cmd:. use gdp_data, clear}{p_end}
{phang2}{cmd:. tsset quarter}{p_end}
{phang2}{cmd:. fbnardl gdp_growth unemployment, decompose(inflation) maxlag(4) ic(aic)}{p_end}

{pstd}
Tests whether positive inflation shocks (rising prices) have a different
effect on GDP growth than negative shocks (falling prices), while controlling
for unemployment and accounting for structural breaks via Fourier terms.
{p_end}

{pstd}
{bf:{ul:Case 10: Accessing stored results}}
{p_end}

{phang2}{cmd:. ereturn list}{p_end}

{phang2}{cmd:. display "Model: " e(model_spec)}{p_end}
{phang2}{cmd:. display "ECM coefficient: " e(alpha)}{p_end}
{phang2}{cmd:. display "Half-life: " e(halflife) " periods"}{p_end}
{phang2}{cmd:. display "Optimal k*: " e(best_kstar)}{p_end}
{phang2}{cmd:. display "F_overall: " e(Fov)}{p_end}
{phang2}{cmd:. display "R-squared: " e(r2)}{p_end}


{marker interpretation}{...}
{title:Interpretation guide}

{pstd}
{ul:Table 3 {hline 2} Reading multipliers}
{p_end}

{pstd}
{bf:Short-run multipliers (SR):} Immediate effect of a unit change. For decomposed
variables, SR+ and SR- measure the impact of positive and negative shocks separately.
{p_end}

{pstd}
{bf:Long-run multipliers (LR):} Total equilibrium effect of a permanent unit change.
If |LR+/LR-| > 1, positive shocks have a proportionally larger long-run effect.
{p_end}

{pstd}
{bf:Asymmetry ratios:} |SR+/SR-| and |LR+/LR-| near 1 indicate near symmetry.
Values far from 1 suggest meaningful asymmetry.
{p_end}

{pstd}
{ul:Table 4 {hline 2} Reading Wald tests}
{p_end}

{pstd}
A significant {bf:short-run asymmetry test} (p < 0.05) means the contemporaneous
impact of a positive shock differs from a negative shock.
{p_end}

{pstd}
A significant {bf:long-run asymmetry test} means the total equilibrium effects
differ. This is the key test for the NARDL framework.
{p_end}

{pstd}
{ul:Table 5 {hline 2} Cointegration decision}
{p_end}

{pstd}
Cointegration is confirmed when all three hold:
(1) F_overall exceeds the upper I(1) bound (or bootstrap p < 0.05),
(2) t_dependent is significant, and
(3) F_independent is significant.
See McNown, Sam & Goh (2018) for the augmented ARDL bounds test.
{p_end}

{pstd}
{ul:Table 7 {hline 2} Half-life}
{p_end}

{pstd}
The ECM coefficient alpha must be negative and significant for valid error correction.
A half-life of 2 (quarterly data) means half the disequilibrium is corrected in
2 quarters.
{p_end}

{pstd}
{ul:Table 8 {hline 2} Fourier significance}
{p_end}

{pstd}
If the joint F-test on Fourier terms is significant (p < 0.05), the Fourier
specification is preferred over pure NARDL. If insignificant, consider
{opt nofourier}.
{p_end}

{pstd}
{ul:Overshoot}
{p_end}

{pstd}
When the impact multiplier (h=0) exceeds the effective long-run multiplier,
the system "overshoots" {hline 2} it over-reacts initially then partially reverses.
In this case, half-life is reported as "Overshoot" rather than a period count.
{p_end}


{marker references}{...}
{title:References}

{phang}
Bertelli, S., Vacca, G. & Zoia, M. (2022). Bootstrap cointegration tests in
ARDL models. {it:Economic Modelling}, 116, 105987.
{p_end}

{phang}
Enders, W. & Lee, J. (2012). The flexible Fourier form and Dickey-Fuller type
unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Kripfganz, S. & Schneider, D.C. (2020). Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics}, 82(6), 1456-1481.
{p_end}

{phang}
McNown, R., Sam, C.Y. & Goh, S.K. (2018). Bootstrapping the autoregressive
distributed lag test for cointegration.
{it:Applied Economics}, 50(13), 1509-1521.
{p_end}

{phang}
Pesaran, M.H. & Shin, Y. (1996). Cointegration and speed of convergence to
equilibrium. {it:Journal of Econometrics}, 71(1-2), 117-143.
{p_end}

{phang}
Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). Bounds testing approaches to the
analysis of level relationships.
{it:Journal of Applied Econometrics}, 16(3), 289-326.
{p_end}

{phang}
Shin, Y., Yu, B. & Greenwood-Nimmo, M. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In R.
Sickles & W. Horrace (Eds.), {it:Festschrift in Honor of Peter Schmidt}.
Springer, 281-314.
{p_end}

{phang}
Yilanci, V., Bozoklu, S. & Gorus, M.S. (2020). Are BRICS countries pollution
havens? Evidence from a bootstrap ARDL bounds testing approach with a Fourier
function. {it:Sustainable Cities and Society}, 55, 102035.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}

{pstd}
Please cite as:{break}
Roudane, M. (2026). {cmd:fbnardl}: Fourier Bootstrap Nonlinear ARDL for Stata.
{p_end}
