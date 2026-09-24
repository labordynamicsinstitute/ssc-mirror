{smcl}
{* *! version 2.0.0  22sep2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] ardl" "help ardl"}{...}
{vieweralsosee "[R] nardl" "help nardl"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{viewerjumpto "Syntax" "fbnardl##syntax"}{...}
{viewerjumpto "Description" "fbnardl##description"}{...}
{viewerjumpto "Methodology" "fbnardl##methodology"}{...}
{viewerjumpto "Options" "fbnardl##options"}{...}
{viewerjumpto "Fixed regressors and dummies" "fbnardl##exog"}{...}
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
{synopt:{opt exo:g(varlist)}}fixed (exogenous) regressors such as dummies;
see {help fbnardl##exog:Fixed regressors and dummies}{p_end}
{synopt:{opt fix:ed(varlist)}}synonym for {opt exog()}{p_end}

{syntab:Standard errors}
{synopt:{opt hac(string)}}{bf:hetero} (White HC1), {bf:auto} or {bf:both}
(Newey-West HAC), or {bf:none} (default){p_end}
{synopt:{opt haclags(#)}}Newey-West truncation lag; default is automatic{p_end}

{syntab:Bootstrap ({cmd:type(fbnardl)} only)}
{synopt:{opt reps(#)}}bootstrap replications; default {bf:999}{p_end}
{synopt:{opt b:ootstrap(string)}}{bf:bvz} (default) or {bf:mcnown}{p_end}
{synopt:{opt xdgp(string)}}marginal process for x in the bootstrap:
{bf:rw} (default) or {bf:vecm}{p_end}

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
{it:depvar} and {it:control_vars} must be plain variable names (generate a
transformed variable first if needed); variables in {opt decompose()} may
carry time-series operators, and {opt exog()} accepts time-series operators
and factor variables.
{p_end}

{p 4 6 2}
The estimation sample must be contiguous (no internal gaps); {cmd:fbnardl}
stops with an error otherwise, because the recursive bootstrap, the
Newey-West estimator and the recursive residuals all require it.
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
{bf:3. Bootstrap cointegration testing:} Optionally bootstraps the three test
statistics under the null with a recursive, null-imposed residual bootstrap,
in the conditional form of Bertelli, Vacca & Zoia (2022) or the
unconditional form of McNown, Sam & Goh (2018).
{p_end}

{pstd}
Fixed regressors such as crisis, policy or break dummies enter through
{opt exog()} and are held fixed inside the bootstrap; heteroskedasticity-
and autocorrelation-robust standard errors ({opt hac()}) are applied to every
reported statistic and inside every bootstrap replication; and a full
diagnostic battery (normality, Breusch-Godfrey, Ljung-Box, Durbin's
alternative, Breusch-Pagan, White, ARCH, RESET, CUSUM and CUSUMSQ on
recursive residuals) is reported.
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
{it:+ lambda1 * sin(2*pi*k*t/T) + lambda2 * cos(2*pi*k*t/T) + SUM(m) delta_m * d_m,t + epsilon_t}
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
{cmd:d_m,t} = optional fixed regressors from {opt exog()} (dummies, seasonal
indicators, exogenous controls), entering once, unlagged, outside the
long-run relationship and outside the cointegration tests
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
Each variable may have a different optimal lag order. Every candidate is
estimated on the {it:same} sample, the one implied by {opt maxlag()} (the
first {it:maxlag}+1 observations are dropped for all of them), so the
information criteria are comparable across candidates; the final model is
estimated on that sample too.
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
Cumulative dynamic multipliers M(h) trace the effect on y of a unit
{it:permanent} shock in a partial sum or control, obtained by simulating the
estimated error-correction equation forward with all of its lag structure,
including the adjustment on y(t-1) and the pull of the lagged level
x(t-1). They therefore converge to the long-run multiplier -beta/alpha by
construction. Confidence bands come from parametric draws of the
coefficient vector from N(b, V) (500 by default). For decomposed variables
M+(h), M-(h) and the asymmetry M+(h) - M-(h) with its band are shown,
as in Shin et al. (2014); for controls a single path.
{p_end}

{pstd}
{ul:Cointegration Testing}
{p_end}

{pstd}
{bf:type(fnardl)} {hline 2} PSS bounds test (Pesaran, Shin & Smith, 2001).
F_overall and t_dependent are compared with the finite-sample Case III
bounds of Kripfganz & Schneider (2020), computed by {cmd:ardlbounds} when
it is installed (k = 2 per decomposed variable + 1 per control; the
short-run count passed to the response surface includes the Fourier terms
and the fixed regressors); approximate PSS (2001) asymptotic bounds
otherwise. F_independent has no tabulated bounds under I(1) regressors; its
statistic is printed but its regression p-value is deliberately not, because
it is invalid in that setting.
{p_end}

{pstd}
{bf:type(fbnardl)} {hline 2} recursive null-imposed residual bootstrap of the
three statistics, in Mata. {cmd:bootstrap(bvz)} (default) follows Bertelli,
Vacca & Zoia (2022): a separate restricted D.y equation per null (their
eqs. 16-18), a marginal VECM for the forcing variables that excludes y(t-1)
(eqs. 19-20). {cmd:bootstrap(mcnown)} follows McNown, Sam & Goh (2018): one
restricted equation for all three tests (their Step 1) and marginal
equations that include y(t-1) (eq. 12). In both, residuals are recentred
and degrees-of-freedom rescaled, the joint residual vector is resampled as
a block, the pseudo-series are cumulated recursively, y*(t) = y*(t-1) +
Dy*(t) and x*(t) = x*(t-1) + Dx*(t), and the initial conditions are drawn
as a contiguous block from the data. The partial sums, the Fourier terms
and the fixed regressors enter the bootstrap equations exactly as they enter
the estimated one, and the statistics inside each replication use the same
covariance estimator as the observed ones ({opt hac()}). {cmd:xdgp(rw)}
imposes the unit root on the forcing variables in the bootstrap;
{cmd:xdgp(vecm)} uses the estimated marginal VECM including the levels.
Critical values at 10%, 5% and 1% and bootstrap p-values are reported.
{p_end}

{pstd}
{ul:Diagnostic Tests}
{p_end}

{phang2}Normality: Jarque-Bera (with skewness and kurtosis), Shapiro-Wilk,
Shapiro-Francia{p_end}
{phang2}Serial correlation: Breusch-Godfrey LM at lags 1-4 (the genuine
auxiliary regression on the original regressors plus lagged residuals, which
stays valid with a lagged dependent variable), Ljung-Box Q(12), Durbin's
alternative test, Durbin-Watson (informational only){p_end}
{phang2}Heteroskedasticity: Breusch-Pagan / Cook-Weisberg, White's general
test, ARCH LM at lags 1 and 4{p_end}
{phang2}Functional form: Ramsey RESET{p_end}
{phang2}Stability: CUSUM and CUSUM of squares computed on recursive
residuals (Brown, Durbin & Evans 1975) with their expanding 5% bands;
CUSUM is on the same scale as {cmd:estat sbcusum}{p_end}

{pstd}
The diagnostics are computed on the OLS fit, because the {cmd:estat} tests
need it; when {opt hac()} is used the reported standard errors already
correct for what the tests detect, and the table says so.
{p_end}

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

{phang}
{opt exog(varlist)} specifies {bf:fixed (exogenous) regressors}: step,
pulse, window or seasonal dummies, or an exogenous control that should not
be part of the long-run relationship. Time-series operators and factor
variables are allowed ({cmd:exog(L.d)}, {cmd:exog(i.month)}). Fixed
regressors enter every candidate model of both selection steps, the final
equation, the CUSUM recursion and the bootstrap data-generating process
(held at their sample values), but are not lagged, not decomposed, not
given a lagged level, and take no part in F_overall, t_dependent or
F_independent; they do not change {it:k}. They are reported in Panel C
(FIXED) of Table 2 and stored in {cmd:e(exog)} and {cmd:e(n_exog)}. See
{help fbnardl##exog:Fixed regressors and dummy variables} for step-by-step
code. A fixed regressor may not be the dependent variable, a control or a
decomposed variable (or a lag or factor of one), and each must vary on the
estimation sample; a dummy that is identically 0 or 1 there is refused with
a message.
{p_end}

{phang}
{opt fixed(varlist)} is a synonym for {opt exog()}; the two lists are
combined if both are given.
{p_end}

{dlgtab:Standard errors}

{phang}
{opt hac(string)} chooses the covariance matrix used for every reported
standard error, t statistic, p-value and Wald test (Tables 2-5), and inside
the bootstrap. {cmd:hetero} is the heteroskedasticity-consistent estimator
of White (1980), computed as HC1; {cmd:auto} and {cmd:both} are the
heteroskedasticity- and autocorrelation-consistent estimator of Newey &
West (1987) with a Bartlett kernel; {cmd:none} (the default) is
conventional OLS. Point estimates are identical under all of them. Use
{cmd:hac(both)} when the diagnostics flag serial correlation or ARCH.
Combined with {cmd:type(fnardl)} the tabulated bounds, which assume i.i.d.
errors, become approximate and the command warns; {cmd:type(fbnardl)}
bootstraps the critical values under the same estimator and is the
internally consistent choice.
{p_end}

{phang}
{opt haclags(#)} sets the Newey-West truncation lag. The default is the
automatic bandwidth floor(4*(T/100)^(2/9)).
{p_end}

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} number of bootstrap replications for {cmd:type(fbnardl)}.
Default 999. Use 99 for exploratory; 999-1999 for final; 4999+ for publication.
{p_end}

{phang}
{opt bootstrap(string)} selects {cmd:bvz} (Bertelli, Vacca & Zoia 2022,
default) or {cmd:mcnown} (McNown, Sam & Goh 2018); see
{help fbnardl##methodology:Methodology}.
{p_end}

{phang}
{opt xdgp(string)} controls how the forcing variables are generated in the
bootstrap: {cmd:rw} (default) imposes the unit root, {cmd:vecm} uses the
estimated marginal VECM including the levels.
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


{marker exog}{...}
{title:Fixed regressors and dummy variables}

{pstd}
This section shows, line by line, how to build the usual kinds of dummy
variable and pass them to {opt exog()}. The data must be {helpb tsset}. The
examples use a monthly variable {cmd:period} in {cmd:%tm} format; for
quarterly or yearly data replace {cmd:tm()} with {cmd:tq()} or a plain year.

{pstd}
{bf:What exog() does and does not do.} A variable in {opt exog()} enters the
estimated equation once, contemporaneously, exactly as typed. It is
{it:not} lag-searched, {it:not} decomposed into partial sums, {it:not}
given a lagged level, {it:not} part of the long-run relationship, {it:not}
in F_overall, t_dependent or F_independent, does {it:not} change {it:k},
and does {it:not} receive a dynamic multiplier. It {it:is} in the Step 1
Fourier search, in every candidate of the Step 2 lag search, in the final
equation, in the diagnostics and CUSUM recursion, and in the conditional
and marginal equations of the bootstrap, where it is held at its sample
values in every replication. Its coefficient appears in Panel C (FIXED) of
Table 2.

{pstd}
{bf:Step 1: check the time variable}, because the dummy condition must be
written in its format.

{phang2}{cmd:. tsset}{p_end}
{phang2}{cmd:. describe period}{p_end}
{phang2}{cmd:. list period in 1/3}{p_end}

{pstd}
{bf:Step 2: build the dummy} with {cmd:generate byte} and a logical
expression (1 when true, 0 when false).

{pstd}{it:Level-shift (step) dummy}: 0 before the event, 1 from it onwards.

{phang2}{cmd:. generate byte d_war = (period >= tm(2022m3))}{p_end}

{pstd}{it:Pulse (one-period) dummy}: 1 in a single month.

{phang2}{cmd:. generate byte d_pulse = (period == tm(2020m4))}{p_end}

{pstd}{it:Window (temporary regime) dummy}:

{phang2}{cmd:. generate byte d_covid = inrange(period, tm(2020m4), tm(2021m6))}{p_end}

{pstd}{it:Quarterly and yearly data}:

{phang2}{cmd:. generate byte d_gfc = (qtr >= tq(2008q3))}{p_end}
{phang2}{cmd:. generate byte d_1997 = (year >= 1997)}{p_end}

{pstd}{it:Seasonal dummies} (factor-variable notation drops the base month
itself, so no collinearity with the constant arises):

{phang2}{cmd:. generate byte mon = month(dofm(period))}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) exog(i.mon)}{p_end}

{pstd}{it:A break date found by another test}:

{phang2}{cmd:. local tb = tm(2019m11)}{p_end}
{phang2}{cmd:. generate byte d_break = (period >= `tb')}{p_end}

{pstd}{it:A lagged dummy} may be given with a time-series operator;
{it:a slope shift} (interaction) must be created first:

{phang2}{cmd:. fbnardl y z, decompose(x) exog(d_covid L.d_covid)}{p_end}
{phang2}{cmd:. generate double z_war = z * d_war}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) exog(d_war z_war)}{p_end}

{pstd}
{bf:Step 3: check it.} No missing values on the sample, and it must vary on
the estimation sample, which starts {it:maxlag}+1 periods in.

{phang2}{cmd:. tabulate d_war, missing}{p_end}
{phang2}{cmd:. list period d_war if d_war != L.d_war}{p_end}

{pstd}
{bf:Step 4: estimate.} Nothing else changes.

{phang2}{cmd:. fbnardl y z, decompose(x) type(fnardl) exog(d_war)}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) type(fnardl) exog(d_covid d_pulse) hac(both)}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) type(fbnardl) reps(999) exog(d_covid d_war)}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) type(fbnardl) bootstrap(mcnown) reps(999) hac(both) exog(d_war)}{p_end}
{phang2}{cmd:. fbnardl y z, decompose(x) exog(i.mon d_war)}{p_end}

{pstd}
{bf:Step 5: read the output.} The header lists the fixed regressors and
Table 1 reports how many were actually estimated. Table 2 shows them in
Panel C (FIXED) with the usual t test; the coefficient is the
contemporaneous effect on D.y in the units of y. The three cointegration
statistics and their critical values are computed exactly as without the
dummies. The names and count are stored:

{phang2}{cmd:. display "`e(exog)'"}{p_end}
{phang2}{cmd:. display e(n_exog)}{p_end}

{pstd}
{bf:Choosing between exog(), the Fourier terms and a control.} Use
{opt exog()} for a {it:known} sharp break, an outlier, a one-off event,
seasonality, or an exogenous variable that should not be in the
cointegrating vector. Rely on the Fourier terms for {it:unknown} or
{it:smooth} breaks; the two combine well. Put a variable in
{it:control_vars} instead if it should carry a long-run coefficient and
enter the bounds tests; then {it:k} rises by one and it is lag-searched.

{pstd}
{bf:Errors and notes.} {it:exog(): d_x is constant on the estimation sample}
means the dummy never switches on the sample, usually because the date was
written in the wrong format ({cmd:period >= 2020} instead of
{cmd:period >= tm(2020m3)}).
{it:exog(): x is already the dependent variable, a control or a decomposed variable}
means a variable (or a lag or factor of it) was given both as a regressor
and as a fixed regressor.
{it:note: fixed regressor(s) ... omitted as constant or collinear}
means {cmd:regress} dropped it on the estimation sample (it varies only in
the observations lost to the lags, or duplicates another regressor); it is
not counted in {cmd:e(n_exog)}.
{it:option exog() not allowed} means an older copy of {cmd:fbnardl} is
found first on the {helpb adopath}.


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
Panel A reports the short-run dynamics, Panel B the lagged levels (the
speed of adjustment and the long-run coefficients before normalisation),
Panel C the fixed regressors from {opt exog()} if any, and Panel D the
Fourier terms and the constant. The header of the table names the
covariance estimator in use.
{p_end}

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
{cmd:type(fnardl)}: F_overall and t_dependent are compared with the
Kripfganz & Schneider (2020) finite-sample I(0)/I(1) bounds at 10%, 5% and
1%, with their approximate p-values; F_independent is printed without a
p-value (none is valid under I(1) regressors). Cointegration is concluded
when both F_overall and t_dependent reject at 5%; F_overall rejecting
alone is flagged as the possible degenerate lagged dependent variable case.
{p_end}

{pstd}
{cmd:type(fbnardl)}: bootstrap p-values and 10%, 5%, 1% critical values for
all three statistics, the number of valid replications, and the three-test
decision of Sam, McNown & Goh (2019): cointegration only if all three
reject; F_overall and t_dependent rejecting without F_independent is the
degenerate lagged independent variable case; F_overall and F_independent
rejecting without t_dependent is the degenerate lagged dependent variable
case. {cmd:e(coint_status)} stores the outcome.
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
{bf:Serial correlation:} Breusch-Godfrey LM at lags 1-4, the genuine
auxiliary regression of the residuals on the original regressors plus their
own lags, so the test remains valid with the lagged dependent variable an
ARDL always contains; Ljung-Box Q(12); Durbin's alternative test; and the
Durbin-Watson d, which is informational only because it is biased towards 2
in this setting. H0: no serial correlation. If these reject, consider
{cmd:hac(both)}.
{p_end}

{phang2}
{bf:Heteroskedasticity:} Breusch-Pagan / Cook-Weisberg; White's general
test; ARCH LM at lags 1 and 4. H0: homoskedastic errors. If these reject,
consider {cmd:hac(hetero)}.
{p_end}

{phang2}
{bf:Functional form:} Ramsey RESET test using powers of fitted values.
H0: no omitted nonlinearity. Significant results suggest the linear
specification is inadequate.
{p_end}

{phang2}
{bf:Stability:} CUSUM and CUSUM of squares computed on recursive residuals
(Brown, Durbin & Evans 1975) with the expanding 5% bands; the CUSUM
statistic is on the scale of {cmd:estat sbcusum}. "Stable" means the path
stays inside its band over the whole sample. Graphs {bf:cusum.png} and
{bf:cusumsq.png} are saved.
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
{synopt:{cmd:e(N)}}observations used{p_end}
{synopt:{cmd:e(N_full)}}observations in the marked sample before lag loss{p_end}
{synopt:{cmd:e(best_p)}}selected lag p{p_end}
{synopt:{cmd:e(best_q_{it:var})}}selected lag q of each decomposed variable{p_end}
{synopt:{cmd:e(best_r_{it:var})}}selected lag r of each control{p_end}
{synopt:{cmd:e(maxlag)}}{opt maxlag()} used{p_end}
{synopt:{cmd:e(k)}}number of long-run forcing variables for the bounds{p_end}
{synopt:{cmd:e(n_exog)}}number of fixed regressors estimated{p_end}
{synopt:{cmd:e(haclags)}}Newey-West lag actually used ({opt hac()} only){p_end}
{synopt:{cmd:e(nmodels)}}candidate models estimated in Step 2{p_end}
{synopt:{cmd:e(wald_sr_{it:var})}, {cmd:e(wald_sr_p_{it:var})}}short-run asymmetry Wald chi2 and p-value{p_end}
{synopt:{cmd:e(wald_lr_{it:var})}, {cmd:e(wald_lr_p_{it:var})}}long-run asymmetry Wald chi2 and p-value{p_end}
{synopt:{cmd:e(F_I0_05)}, {cmd:e(F_I1_05)}, {cmd:e(t_I0_05)}, {cmd:e(t_I1_05)}}5% bounds ({cmd:type(fnardl)} with {cmd:ardlbounds}){p_end}
{synopt:{cmd:e(Fov_pval_I0)}, {cmd:e(Fov_pval_I1)}, {cmd:e(t_pval_I0)}, {cmd:e(t_pval_I1)}}Kripfganz-Schneider p-values{p_end}
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
{synopt:{cmd:e(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(bs_nvalid)}}replications that produced a usable statistic{p_end}
{synopt:{cmd:e(bs_Fov_cv01)}, {cmd:e(bs_Fov_cv05)}, {cmd:e(bs_Fov_cv10)}}bootstrap critical values for F_overall{p_end}
{synopt:{cmd:e(bs_Fov_pval)}}bootstrap p-value for F_overall{p_end}
{synopt:{cmd:e(bs_t_cv01)}, {cmd:e(bs_t_cv05)}, {cmd:e(bs_t_cv10)}}bootstrap critical values for t_dependent{p_end}
{synopt:{cmd:e(bs_t_pval)}}bootstrap p-value for t_dependent{p_end}
{synopt:{cmd:e(bs_Find_cv01)}, {cmd:e(bs_Find_cv05)}, {cmd:e(bs_Find_cv10)}}bootstrap critical values for F_independent{p_end}
{synopt:{cmd:e(bs_Find_pval)}}bootstrap p-value for F_independent{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:fbnardl}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(type)}}{cmd:fnardl} or {cmd:fbnardl}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(decompose)}}decomposed variable name(s){p_end}
{synopt:{cmd:e(controls)}}control variable name(s), if any{p_end}
{synopt:{cmd:e(ic)}}information criterion used (aic or bic){p_end}
{synopt:{cmd:e(exog)}}fixed regressors, if any{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:ols}, {cmd:robust} or {cmd:hac}{p_end}
{synopt:{cmd:e(vce)}}description of the covariance estimator{p_end}
{synopt:{cmd:e(bootstrap)}, {cmd:e(xdgp)}}bootstrap settings ({cmd:type(fbnardl)}){p_end}
{synopt:{cmd:e(coint_status)}}{cmd:cointegrated}, {cmd:degenerate_indep},
{cmd:degenerate_dep} or {cmd:no_cointegration}{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the estimated equation{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix under the chosen estimator{p_end}

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
{bf:{ul:Fixed regressors, robust standard errors and the bootstrap}}
(see {help fbnardl##exog:Fixed regressors and dummy variables})
{p_end}

{phang2}{cmd:. gen byte d_step = (t >= 200)}{p_end}
{phang2}{cmd:. gen byte d_pulse = (t == 150)}{p_end}
{phang2}{cmd:. fbnardl y z1, decompose(x1) exog(d_step d_pulse)}{p_end}
{phang2}{cmd:. fbnardl y z1, decompose(x1) exog(d_step) hac(both)}{p_end}
{phang2}{cmd:. fbnardl y z1, decompose(x1) type(fbnardl) reps(999) exog(d_step)}{p_end}
{phang2}{cmd:. fbnardl y z1, decompose(x1) type(fbnardl) bootstrap(mcnown) reps(999) hac(both) exog(d_step)}{p_end}

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
Uses the recursive null-imposed bootstrap instead of the tabulated bounds.
Table 5 then shows bootstrap p-values and 10%, 5%, 1% critical values for
all three statistics and applies the three-test decision rule. Preferred in
small samples, with {opt hac()}, and whenever F_independent matters, since
that statistic has no tabulated bounds. Add {cmd:bootstrap(mcnown)} for the
McNown, Sam & Goh (2018) variant.
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
With {cmd:type(fbnardl)} cointegration is confirmed when all three
bootstrap p-values are below 0.05; F_overall and t_dependent rejecting
without F_independent is the degenerate lagged independent variable case,
and F_overall and F_independent rejecting without t_dependent is the
degenerate lagged dependent variable case (Sam, McNown & Goh 2019). With
{cmd:type(fnardl)} only F_overall and t_dependent can be compared with
tabulated bounds, so the decision rests on those two and F_independent is
reported without inference.
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
Brown, R.L., Durbin, J. & Evans, J.M. (1975). Techniques for testing the
constancy of regression relationships over time.
{it:Journal of the Royal Statistical Society B}, 37(2), 149-192.
{p_end}

{phang}
Newey, W.K. & West, K.D. (1987). A simple, positive semi-definite,
heteroskedasticity and autocorrelation consistent covariance matrix.
{it:Econometrica}, 55(3), 703-708.
{p_end}

{phang}
Pesaran, M.H. & Shin, Y. (1996). Cointegration and speed of convergence to
equilibrium. {it:Journal of Econometrics}, 71(1-2), 117-143.
{p_end}

{phang}
Sam, C.Y., McNown, R. & Goh, S.K. (2019). An augmented autoregressive
distributed lag bounds test for cointegration.
{it:Economic Modelling}, 80, 130-141.
{p_end}

{phang}
White, H. (1980). A heteroskedasticity-consistent covariance matrix
estimator and a direct test for heteroskedasticity.
{it:Econometrica}, 48(4), 817-838.
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
