{smcl}
{* *! version 1.2.0  02aug2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{vieweralsosee "[R] ardl" "help ardl"}{...}
{viewerjumpto "Syntax" "fbardl##syntax"}{...}
{viewerjumpto "Description" "fbardl##description"}{...}
{viewerjumpto "Methodology" "fbardl##methodology"}{...}
{viewerjumpto "Options" "fbardl##options"}{...}
{viewerjumpto "Output tables" "fbardl##tables"}{...}
{viewerjumpto "Graphs" "fbardl##graphs"}{...}
{viewerjumpto "Stored results" "fbardl##results"}{...}
{viewerjumpto "Examples" "fbardl##examples"}{...}
{viewerjumpto "References" "fbardl##references"}{...}
{viewerjumpto "Author" "fbardl##author"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:fbardl} {hline 2}}Fourier Bootstrap Autoregressive Distributed Lag Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:fbardl}
{depvar}
{indepvars}
{ifin}{cmd:,}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt type(string)}}model type: {bf:fardl} (default), {bf:fbardl_mcnown}, or {bf:fbardl_bvz}{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag order for grid search; default {bf:4}{p_end}
{synopt:{opt maxk(#)}}maximum Fourier frequency; default {bf:5}{p_end}
{synopt:{opt ic(string)}}information criterion: {bf:aic} (default) or {bf:bic}{p_end}
{synopt:{opt nof:ourier}}pure ARDL without Fourier terms{p_end}
{synopt:{opt case(#)}}PSS case: {bf:2}, {bf:3} (default), {bf:4}, or {bf:5}{p_end}
{synopt:{opt exo:g(varlist)}}fixed (exogenous) regressors, e.g. dummies{p_end}
{synopt:{opt fix:ed(varlist)}}synonym for {opt exog()}{p_end}
{synopt:{opt uncond:itional}}drop contemporaneous D.x (Yilanci/McNown form){p_end}

{syntab:Standard errors}
{synopt:{opt hac(string)}}covariance estimator: {bf:hetero}, {bf:auto}, {bf:both}, or {bf:none} (default){p_end}
{synopt:{opt haclags(#)}}Newey-West truncation lag; default automatic{p_end}

{syntab:Bootstrap}
{synopt:{opt reps(#)}}bootstrap replications; default {bf:999}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:c(level)}{p_end}
{synopt:{opt hor:izon(#)}}multiplier/persistence horizon; default {bf:20}{p_end}
{synopt:{opt nodiag}}suppress diagnostics{p_end}
{synopt:{opt nodyn:mult}}suppress dynamic multipliers and graphs{p_end}
{synopt:{opt noadv:anced}}suppress advanced analyses{p_end}
{synopt:{opt not:able}}suppress regression table{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:fbardl}; see {helpb tsset}.
{p_end}

{p 4 6 2}
{it:varlist} and {opt exog()} allow time-series operators; {opt exog()} also
allows factor variables.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fbardl} estimates a {bf:Fourier Autoregressive Distributed Lag} (FARDL)
model and performs cointegration testing. It combines three advances:
{p_end}

{phang}
{bf:1. Fourier approximation:} Low-frequency trigonometric terms capture smooth
structural breaks of unknown form, number, and location.
{p_end}

{phang}
{bf:2. Bootstrap cointegration testing:} Two bootstrap procedures compute
finite-sample critical values:
{p_end}

{phang2}
{bf:McNown, Sam & Goh (2018):} Unconditional bootstrap — single restricted
null, residual resampling, three test statistics (F_overall, t_dependent,
F_independent).
{p_end}

{phang2}
{bf:Bertelli, Vacca & Zoia (2022):} Conditional bootstrap — three separate
nulls, marginal VECM for independent variables, targeted bootstrap
distributions.
{p_end}

{phang}
{bf:3. Kripfganz & Schneider (2020) critical values:}
For the non-bootstrap case ({cmd:type(fardl)}), the command uses
response surface regressions from the {cmd:ardlbounds} program to
compute exact finite-sample critical values and approximate p-values.
These are based on ~95 billion simulated F-statistics and ~57 billion
t-statistics. If {cmd:ardlbounds} is not installed, PSS (2001) asymptotic
critical values are used as fallback.
{p_end}


{marker methodology}{...}
{title:Methodology}

{pstd}
{ul:The FARDL Model (ECM form)}
{p_end}

{pstd}
The ARDL(p, q1, ..., qk) error correction model is:
{p_end}

{p 8 8 2}
D.y_t = c + gamma1*sin(2*pi*k*t/T) + gamma2*cos(2*pi*k*t/T)
{p_end}
{p 12 12 2}
+ alpha*L.y_t + SUM beta_i*L.x_it
{p_end}
{p 12 12 2}
+ SUM(j=1..p) phi_j*L(j).D.y_t + SUM(i,j) theta_ij*L(j).D.x_it + e_t
{p_end}

{pstd}
where D. denotes the first difference operator, L. denotes the lag operator,
L(j).D. denotes the j-th lag of the first difference, and the Fourier terms
sin(2*pi*k*t/T) and cos(2*pi*k*t/T) capture smooth structural breaks.
{p_end}

{pstd}
{ul:Time-Series Operator Notation}
{p_end}

{pstd}
This command uses Stata's standard time-series operators:
{p_end}

{phang2}{bf:L.y} = y_{t-1} (lagged level){p_end}
{phang2}{bf:D.y} = y_t - y_{t-1} (first difference){p_end}
{phang2}{bf:L1.D.y} = D.y_{t-1} (first lag of the first difference){p_end}
{phang2}{bf:L2.D.y} = D.y_{t-2} (second lag of the first difference){p_end}

{pstd}
{ul:Two-Step Model Selection (Yilanci et al. 2020)}
{p_end}

{pstd}
{bf:Step 1 {hline 2} Select k* by minimum SSR:}
For each k in {c -(}0.1, 0.2, ..., maxk{c )-}, a maximal ARDL model
is estimated and the SSR recorded. The k with the lowest SSR is selected as k*.
{p_end}

{pstd}
{bf:Step 2 {hline 2} Select lags (p,q) by AIC/BIC with k* fixed:}
Exhaustive grid search over all lag combinations. The model with the
minimum information criterion value is selected.
{p_end}

{pstd}
{ul:Cointegration Test Statistics}
{p_end}

{pstd}
Three test statistics following McNown, Sam & Goh (2018):
{p_end}

{phang2}
{bf:F_overall (F_ov):} Joint test: alpha = beta_1 = ... = beta_k = 0.
Uses all lagged level variables.
{p_end}

{phang2}
{bf:t_dependent (t_DV):} t-test on L.depvar: alpha = 0.
{p_end}

{phang2}
{bf:F_independent (F_ind):} Joint test: beta_1 = ... = beta_k = 0.
Tests for degenerate cases.
{p_end}

{pstd}
{ul:Critical Values}
{p_end}

{pstd}
{bf:type(fardl):} Uses Kripfganz & Schneider (2020) response surface
regressions via the {cmd:ardlbounds} program. Provides finite-sample-adjusted
I(0) and I(1) critical value bounds and approximate p-values at each
significance level. Falls back to PSS (2001) asymptotic tables if
{cmd:ardlbounds} is not installed. Install via:
{cmd:net install ardl, from(http://www.kripfganz.de/stata/)}.
{p_end}

{pstd}
{bf:type(fbardl_mcnown):} McNown et al. (2018) unconditional bootstrap.
{p_end}

{pstd}
{bf:type(fbardl_bvz):} Bertelli et al. (2022) conditional bootstrap.
{p_end}

{pstd}
{ul:The bootstrap data-generating process}
{p_end}

{pstd}
Both procedures are implemented as specified in the source papers:
{p_end}

{phang2}
{bf:1. Restricted estimation.} The ARDL equation is re-estimated with the
restriction of the null imposed, and the restricted residuals are saved.
McNown et al. impose a {ul:single} null {c -} the F_ov null {c -} and read all
three statistics from it (p. 6, Step 1). Bertelli et al. impose a
{ul:separate} null per statistic, Eqs. (16), (17) and (18), and build a
distinct bootstrap sample for each.
{p_end}

{phang2}
{bf:2. Marginal equations.} For McNown et al. the D.x equations are
unrestricted and include the lagged levels of both y and x, so feedback is
allowed (Eq. 12). For Bertelli et al. the marginal VECM contains the lagged
levels of x only, imposing weak exogeneity (Eqs. 19-20).
{p_end}

{phang2}
{bf:3. Recentring.} McNown et al. recentre the residual series before
resampling, with divisor (n-q-1) (Eq. 13). Bertelli et al. recentre each
resampled set inside the replication (Eqs. 21-22). Both follow Davidson &
MacKinnon (2005); {cmd:fbardl} applies each paper's own convention.
{p_end}

{phang2}
{bf:4. Paired resampling.} The ARDL and marginal residuals are drawn with a
single common index, so their contemporaneous correlation is preserved.
{p_end}

{phang2}
{bf:5. Recursive generation.} The bootstrap series are cumulated
recursively, y*_t = y*_{c -(}t-1{c )-} + Dy*_t and x*_t = x*_{c -(}t-1{c )-} +
Dx*_t (McNown et al. Eqs. 7-8; Bertelli et al. Eq. 23). The fitted part of
Dy*_t and Dx*_t is evaluated on the {ul:bootstrap} history, not on the
observed data. Within each period x* is generated before y*, so the
conditional equation can use the contemporaneous Dx*_t.
{p_end}

{phang2}
{bf:6. Critical values} are read off the ordered bootstrap statistics: upper
tail for the two F tests, lower tail for the t test (McNown et al. Eqs. 15-16;
Bertelli et al. Eqs. 24-25).
{p_end}

{pstd}
{it:Initial conditions.} Observations before the first usable row are held at
their observed values. Bertelli et al. instead draw a block of p observations
at random from the original data; conditioning on the observed start is the
more common convention and is what {cmd:fbardl} does.
{p_end}

{pstd}
{it:Verification.} The undocumented option {cmd:dgpcheck} feeds the recursion
the observed residuals in their original order. Because a restricted fitted
value plus its own residual is the observed D.y, the recursion must then
reproduce the observed series exactly; the reported deviations should be at
machine precision.
{p_end}

{pstd}
{ul:Degenerate Case Detection}
{p_end}

{pstd}
The numbering follows {bf:McNown, Sam & Goh (2018, p. 4)}, who define the two
degenerate cases by which block of the level terms is non-zero:
{p_end}

{phang2}
{bf:Degenerate #1 {hline 2} degenerate lagged {ul:dependent} variable}
(pi_yy != 0, pi_yx.x = 0): F_ov and t_DV significant, F_ind {ul:not}.
The joint significance comes solely from the lagged dependent variable, so the
equation reduces to a generalised Dickey-Fuller regression and y_t is in fact
I(0). There is no cointegration.
{p_end}

{phang2}
{bf:Degenerate #2 {hline 2} degenerate lagged {ul:independent} variable}
(pi_yy = 0, pi_yx.x != 0): F_ov and F_ind significant, t_DV {ul:not}.
The dependent variable does not error-correct towards the level relationship,
so again there is no cointegration.
{p_end}

{pstd}
{it:Note:} Yilanci et al. (2020, p. 11) number these two cases the other way
round, and their own p. 12 description contradicts their bullet definitions.
{cmd:fbardl} follows McNown et al., the primary source, which is internally
consistent and is cited by both other papers.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt type(string)} sets the cointegration test type:
{p_end}

{phang2}
{cmd:type(fardl)} (default): Fourier ARDL with PSS bounds test. Uses
Kripfganz & Schneider (2020) finite-sample critical values and approximate
p-values from the {cmd:ardlbounds} program.
{p_end}

{phang2}
{cmd:type(fbardl_mcnown)}: McNown, Sam & Goh (2018) unconditional
bootstrap procedure.
{p_end}

{phang2}
{cmd:type(fbardl_bvz)}: Bertelli, Vacca & Zoia (2022) conditional
bootstrap procedure.
{p_end}

{phang}
{opt maxlag(#)} maximum lag order p and q for grid search. Default is 4.
{p_end}

{phang}
{opt maxk(#)} maximum Fourier frequency. Default is 5.
The search grid uses increments of 0.1 (i.e. k = 0.1, 0.2, ..., maxk).
{p_end}

{phang}
{opt ic(string)} information criterion for lag selection: {cmd:aic} or {cmd:bic}.
Default is {cmd:aic}.
{p_end}

{phang}
{opt nofourier} estimates pure ARDL without Fourier terms. Useful as a
comparison benchmark.
{p_end}

{phang}
{opt case(#)} PSS (2001) deterministic specification. Default is 3. The case
determines both the terms included in the estimated equation and the
restriction tested by F_ov:
{p_end}

{p2colset 9 26 28 2}{...}
{p2col:{bf:case(2)}}restricted intercept, no trend {c -} F_ov restricts the
lagged levels {ul:and the intercept}{p_end}
{p2col:{bf:case(3)}}unrestricted intercept, no trend {c -} F_ov restricts the
lagged levels only{p_end}
{p2col:{bf:case(4)}}unrestricted intercept, restricted trend {c -} a linear
trend is added to the equation and F_ov restricts the lagged levels {ul:and
the trend}{p_end}
{p2col:{bf:case(5)}}unrestricted intercept and trend {c -} a linear trend is
added and F_ov restricts the lagged levels only{p_end}
{p2colreset}{...}

{phang}
Cases 4 and 5 therefore estimate a different model from cases 2 and 3, and the
trend coefficient is reported in Table 2. Under {cmd:case(2)} the restricted
model that generates the bootstrap data is estimated with {cmd:noconstant},
following Bertelli et al. (2022), step 1.
{p_end}

{phang}
{opt unconditional} estimates the {bf:unconditional} ARDL equation, in which
the contemporaneous differences D.x are excluded and the short-run x terms run
from lag 1. This is the specification of Yilanci et al. (2020, Eq. 8) and
McNown et al. (2018, Eq. 10). The default is the {bf:conditional} equation of
Pesaran, Shin & Smith (2001, Eq. 4), which includes D.x and is the form
Bertelli et al. (2022) argue for. Use this option to reproduce results
published with the original Yilanci or McNown specification.
{p_end}

{phang}
{opt exog(varlist)} specifies {bf:fixed (exogenous) regressors} — typically
step dummies, pulse/outlier dummies, seasonal dummies, or a deterministic
trend. Time-series operators and factor variables are allowed, so
{cmd:exog(i.quarter)} and {cmd:exog(L.shock)} both work.
{p_end}

{phang2}
Fixed regressors enter {it:contemporaneously and without lag selection}:
they are included in the Step 1 SSR search for k*, in every candidate model
of the Step 2 AIC/BIC search, and in the final estimated equation. They are
reported in their own {bf:FIXED} block in Table 2 and are counted in the
number of short-run coefficients passed to {cmd:ardlbounds}.
{p_end}

{phang2}
They are deliberately {bf:excluded from the long-run relationship}: no lagged
level of a fixed regressor is added, and they take no part in the F_overall or
F_independent tests. This is what distinguishes a fixed regressor from an
{it:indepvar}. Use {opt exog()} when a variable must be controlled for but is
not part of the cointegrating relationship being tested.
{p_end}

{phang}
{opt fixed(varlist)} is a synonym for {opt exog()}. If both are given the two
lists are combined.
{p_end}

{dlgtab:Standard errors}

{phang}
{opt hac(string)} selects the covariance matrix estimator used for inference.
The {bf:point estimates are identical} under every choice; what changes are the
standard errors, t/z statistics, p-values, confidence intervals and Wald (F)
statistics.
{p_end}

{phang2}
{cmd:hac(hetero)} — heteroskedasticity-consistent standard errors
(White, 1980), computed as Stata's HC1. Synonyms: {cmd:het}, {cmd:robust},
{cmd:white}, {cmd:hc1}.
{p_end}

{phang2}
{cmd:hac(auto)} — autocorrelation-consistent standard errors, computed with
the Newey & West (1987) Bartlett kernel. Synonyms: {cmd:ac}, {cmd:serial}.
Note that a HAC estimator is robust to heteroskedasticity as well, by
construction, so {cmd:hac(auto)} and {cmd:hac(both)} are the same estimator.
There is no consistent kernel estimator that corrects for autocorrelation
while assuming homoskedasticity.
{p_end}

{phang2}
{cmd:hac(both)} — heteroskedasticity- {it:and} autocorrelation-consistent
(HAC) standard errors, Newey & West (1987). Synonyms: {cmd:hac}, {cmd:nw},
{cmd:newey}.
{p_end}

{phang2}
{cmd:hac(none)} (default) — conventional OLS standard errors, valid under
i.i.d. errors.
{p_end}

{phang}
{opt haclags(#)} sets the Newey-West truncation lag. Requires {cmd:hac(auto)}
or {cmd:hac(both)}. If omitted, the automatic bandwidth
{bf:floor(4*(T/100)^(2/9))} is used (Newey & West, 1994). Must be spelled out
in full; it cannot be abbreviated.
{p_end}

{pstd}
{ul:Interaction with the cointegration test}
{p_end}

{phang}
This matters and is not cosmetic. The Pesaran, Shin & Smith (2001) and
Kripfganz & Schneider (2020) critical value bounds are {bf:simulated under
i.i.d. errors}. If you request {opt hac()} together with {cmd:type(fardl)},
the F and t statistics reported in Table 3 no longer follow the distribution
those bounds were tabulated from, so comparing them against the bounds is an
approximation. {cmd:fbardl} prints a warning when you do this.
{p_end}

{phang}
The bootstrap types do not have this problem. With {cmd:type(fbardl_mcnown)}
or {cmd:type(fbardl_bvz)} the {it:same} covariance estimator is applied to the
observed sample and to every bootstrap replication, so the critical values are
re-derived under that estimator and the test remains internally consistent.
{bf:If your errors are heteroskedastic or serially correlated, prefer a
bootstrap type over the tabulated bounds.}
{p_end}

{phang}
Diagnostic tests in Table 4 are still computed and reported when {opt hac()}
is used. They describe the error process; they are not invalidated by the
choice of covariance estimator, and they remain the evidence on which that
choice should be based. Ramsey's RESET is computed from the OLS fit, since
{cmd:estat ovtest} is not available after {helpb newey}.
{p_end}

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} number of bootstrap replications. Default 999.
Recommendations: 99 for exploratory work; 999 for standard analysis;
1999-4999 for publication.
{p_end}

{dlgtab:Reporting}

{phang}
{opt level(#)} confidence level for long-run multiplier CIs.
Default is {cmd:c(level)} (usually 95).
{p_end}

{phang}
{opt horizon(#)} maximum horizon for dynamic multipliers and persistence
profile. Default is 20.
{p_end}


{marker tables}{...}
{title:Output tables}

{pstd}
{cmd:fbardl} produces up to 8 publication-quality tables:
{p_end}

{phang2}Table 1: Model Selection Summary (ARDL spec, k*, N, R2, AIC/BIC){p_end}
{phang2}Table 2: ARDL(p,q1,...,qk) regression, EC representation{p_end}
{phang3}ADJ — Speed of Adjustment (L.y){p_end}
{phang3}LR — Long-Run Coefficients (-beta/alpha, delta method via nlcom){p_end}
{phang3}SR — Short-Run Coefficients (individual D.x, LD.x, ...){p_end}
{phang3}FIXED — Fixed (Exogenous) Regressors, if {opt exog()} was given{p_end}
{phang3}Fourier Terms & Deterministics{p_end}
{phang2}Table 3: Cointegration Test Results (F_ov, t_DV, F_ind with CVs/p-values){p_end}
{phang2}Table 4: Diagnostic Tests{p_end}
{phang3}A. Normality: Jarque-Bera, Shapiro-Wilk, Shapiro-Francia{p_end}
{phang3}B. Serial correlation: Breusch-Godfrey LM(1-4), Ljung-Box Q(12),
Durbin's alternative, Durbin-Watson (reference only){p_end}
{phang3}C. Heteroskedasticity: Breusch-Pagan/Cook-Weisberg, White, ARCH LM(1,4){p_end}
{phang3}D. Functional form: Ramsey RESET{p_end}
{phang3}E. Parameter stability: CUSUM and CUSUM of squares{p_end}
{phang2}Table 5: Dynamic Multipliers (by horizon){p_end}
{phang2}Table 6: Half-Life & Persistence Profile (mean adj. lag, 90%/99% adjustment){p_end}
{phang2}Table 7: Fourier Terms Joint Significance F-test{p_end}
{phang2}Table 8: Long-Run Equilibrium Relationship{p_end}


{pstd}
{ul:Notes on the diagnostic tests}
{p_end}

{phang}
{bf:Serial correlation.} The Breusch-Godfrey auxiliary regression includes the
original regressors alongside the lagged residuals. That is what keeps it valid
when the equation contains a lagged dependent variable, which an ARDL always
does. Regressing the residuals on their own lags alone is a different and, in
this setting, invalid test.
{p_end}

{phang}
{bf:Durbin-Watson} is printed for reference but should not be used here: it is
biased towards 2 whenever a lagged dependent variable appears among the
regressors. Read the Breusch-Godfrey and Durbin alternative tests instead.
{p_end}

{phang}
{bf:Heteroskedasticity.} Breusch-Pagan and White test for heteroskedasticity
in the levels of the regressors and bear on the choice of {opt hac(hetero)}.
The ARCH LM tests concern conditional variance over time and are a different
question.
{p_end}

{phang}
{bf:Stability.} CUSUM and CUSUM of squares are computed on {bf:recursive}
residuals, as Brown, Durbin & Evans (1975) define them, with their expanding
bands. The CUSUM statistic is normalised so that it is compared against
0.9479 at 5%, the same scale Stata's {helpb estat sbcusum} reports; it may
differ marginally from that command because the first, exactly identified
recursive residual is omitted. The CUSUM-of-squares critical value is the
Kolmogorov-Smirnov approximation to the BDE table. CUSUM has power against
shifts in the mean of the recursive residuals, CUSUM of squares against shifts
in their variance, so a change in slope typically shows up only in the latter.
{p_end}


{marker graphs}{...}
{title:Graphs}

{pstd}
All graphs use publication-quality styling (white background, modern colors,
labeled axes):
{p_end}

{phang2}{bf:kstar_selection}: SSR vs k* frequency selection scatter{p_end}
{phang2}{bf:dynmult_varname}: Dynamic multiplier area chart (per variable){p_end}
{phang2}{bf:cummult_varname}: Cumulative multiplier with LR target line{p_end}
{phang2}{bf:persistence_profile}: Pesaran & Shin (1996) persistence profile{p_end}
{phang2}{bf:cusum}: CUSUM of recursive residuals with 5% BDE bands{p_end}
{phang2}{bf:cusumsq}: CUSUM of squares with 5% BDE bands{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fbardl} stores the following in {cmd:e()}:
{p_end}

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(best_p)}}selected lag p{p_end}
{synopt:{cmd:e(best_kstar)}}selected Fourier frequency k*{p_end}
{synopt:{cmd:e(aic)}}AIC{p_end}
{synopt:{cmd:e(bic)}}BIC{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(Fov)}}F_overall statistic{p_end}
{synopt:{cmd:e(t_dep)}}t_dependent statistic{p_end}
{synopt:{cmd:e(Find)}}F_independent statistic{p_end}
{synopt:{cmd:e(ecm_coef)}}ECM coefficient (alpha){p_end}
{synopt:{cmd:e(n_exog)}}number of estimated fixed regressors{p_end}
{synopt:{cmd:e(haclags)}}Newey-West truncation lag (only if {cmd:hac(auto|both)}){p_end}

{p2col 5 28 32 2: Bootstrap only (fbardl_mcnown / fbardl_bvz)}{p_end}
{synopt:{cmd:e(Fov_pval)}}bootstrap p-value (F_overall){p_end}
{synopt:{cmd:e(t_pval)}}bootstrap p-value (t_dependent){p_end}
{synopt:{cmd:e(Find_pval)}}bootstrap p-value (F_independent){p_end}
{synopt:{cmd:e(Fov_cv05)}}bootstrap 5% critical value (F_overall){p_end}
{synopt:{cmd:e(t_cv05)}}bootstrap 5% critical value (t_dependent){p_end}
{synopt:{cmd:e(Find_cv05)}}bootstrap 5% critical value (F_independent){p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications{p_end}

{p2col 5 28 32 2: PSS only (fardl){c -} Kripfganz & Schneider (2020)}{p_end}
{synopt:{cmd:e(Fov_pval_I0)}}approximate p-value under I(0) (F_overall){p_end}
{synopt:{cmd:e(Fov_pval_I1)}}approximate p-value under I(1) (F_overall){p_end}
{synopt:{cmd:e(t_pval_I0)}}approximate p-value under I(0) (t_dependent){p_end}
{synopt:{cmd:e(t_pval_I1)}}approximate p-value under I(1) (t_dependent){p_end}
{synopt:{cmd:e(F_I0_05)}}5% I(0) critical value (F-test){p_end}
{synopt:{cmd:e(F_I1_05)}}5% I(1) critical value (F-test){p_end}
{synopt:{cmd:e(t_I0_05)}}5% I(0) critical value (t-test){p_end}
{synopt:{cmd:e(t_I1_05)}}5% I(1) critical value (t-test){p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}"fbardl"{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}independent variable(s){p_end}
{synopt:{cmd:e(exog)}}fixed (exogenous) regressors{p_end}
{synopt:{cmd:e(type)}}model type{p_end}
{synopt:{cmd:e(ic)}}information criterion used{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:ols}, {cmd:robust}, or {cmd:hac}{p_end}
{synopt:{cmd:e(vce)}}description of the covariance estimator used{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1: Fourier ARDL with PSS bounds test}{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fardl) maxlag(4) maxk(3) ic(aic)}{p_end}

{pstd}{bf:Example 2: Fourier Bootstrap ARDL — McNown et al. (2018)}{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fbardl_mcnown) maxlag(3) maxk(2) reps(999)}{p_end}

{pstd}{bf:Example 3: Fourier Bootstrap ARDL — Bertelli et al. (2022)}{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fbardl_bvz) maxlag(3) maxk(2) reps(999)}{p_end}

{pstd}{bf:Example 4: Pure ARDL (no Fourier terms)}{p_end}
{phang}{cmd:. fbardl y x1, nofourier maxlag(4) ic(bic)}{p_end}

{pstd}{bf:Example 5: Minimal output}{p_end}
{phang}{cmd:. fbardl y x1 x2, nodiag nodynmult noadvanced maxlag(2)}{p_end}

{pstd}{bf:Example 6: Access stored results}{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fbardl_mcnown) reps(999)}{p_end}
{phang}{cmd:. di e(Fov)}{space 8}// F_overall statistic{p_end}
{phang}{cmd:. di e(Fov_pval)}{space 4}// Bootstrap p-value{p_end}
{phang}{cmd:. di e(best_kstar)}{space 2}// Optimal Fourier frequency{p_end}

{pstd}{bf:Example 7: Heteroskedasticity-robust standard errors}{p_end}
{phang}{cmd:. fbardl y x1 x2, hac(hetero)}{p_end}

{pstd}
{bf:Example 8: Heteroskedasticity- and autocorrelation-robust (HAC) errors}
{p_end}
{phang}{cmd:. fbardl y x1 x2, hac(both)}{space 21}// automatic lag{p_end}
{phang}{cmd:. fbardl y x1 x2, hac(both) haclags(6)}{space 8}// fixed lag{p_end}

{pstd}
{bf:Example 9: HAC errors with bootstrap critical values (recommended when}
{bf:the diagnostics reject homoskedasticity or no-serial-correlation)}
{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fbardl_mcnown) reps(999) hac(both)}{p_end}

{pstd}{bf:Example 10: Fixed regressors — a COVID step dummy and a pulse}{p_end}
{phang}{cmd:. gen byte covid = inrange(period, tm(2020m3), tm(2021m12))}{p_end}
{phang}{cmd:. gen byte pulse = (period == tm(2020m4))}{p_end}
{phang}{cmd:. fbardl y x1 x2, exog(covid pulse)}{p_end}

{pstd}{bf:Example 11: Factor-variable dummies and a deterministic trend}{p_end}
{phang}{cmd:. fbardl y x1 x2, exog(i.quarter trend)}{p_end}

{pstd}{bf:Example 12: Everything combined}{p_end}
{phang}{cmd:. fbardl y x1 x2, type(fbardl_bvz) reps(999) hac(both) exog(covid)}{p_end}
{phang}{cmd:. di e(vce)}{space 10}// covariance estimator used{p_end}
{phang}{cmd:. di e(n_exog)}{space 7}// number of fixed regressors estimated{p_end}


{marker references}{...}
{title:References}

{phang}
Becker, R., Enders, W. & Lee, J. (2006). A stationarity test in the presence
of an unknown number of smooth breaks. {it:Journal of Time Series Analysis},
27(3), 381-409.
{p_end}

{phang}
Bertelli, S., Vacca, G. & Zoia, M. (2022). Bootstrap cointegration tests in
ARDL models. {it:Economic Modelling}, 116, 105987.
{p_end}

{phang}
Brown, R.L., Durbin, J. & Evans, J.M. (1975). Techniques for testing the
constancy of regression relationships over time. {it:Journal of the Royal
Statistical Society, Series B}, 37(2), 149-192.
{p_end}

{phang}
Davidson, R. & MacKinnon, J.G. (2005). The case against JIVE.
{it:Journal of Applied Econometrics}, 21(6), 827-833.
{p_end}

{phang}
Enders, W. & Lee, J. (2012). The flexible Fourier form and Dickey-Fuller type
unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Kripfganz, S. & Schneider, D.C. (2020). Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics}, 82, 1456-1481.
{p_end}

{phang}
McNown, R., Sam, C.Y. & Goh, S.K. (2018). Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics}, 50(13), 1509-1521.
{p_end}

{phang}
Newey, W.K. & West, K.D. (1987). A simple, positive semi-definite,
heteroskedasticity and autocorrelation consistent covariance matrix.
{it:Econometrica}, 55(3), 703-708.
{p_end}

{phang}
Newey, W.K. & West, K.D. (1994). Automatic lag selection in covariance matrix
estimation. {it:Review of Economic Studies}, 61(4), 631-653.
{p_end}

{phang}
Pesaran, M.H. & Shin, Y. (1996). Cointegration and speed of convergence to
equilibrium. {it:Journal of Econometrics}, 71(1-2), 117-143.
{p_end}

{phang}
Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). Bounds testing approaches to
the analysis of level relationships. {it:Journal of Applied Econometrics},
16(3), 289-326.
{p_end}

{phang}
White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator
and a direct test for heteroskedasticity. {it:Econometrica}, 48(4), 817-838.
{p_end}

{phang}
Yilanci, V., Bozoklu, S. & Gorus, M.S. (2020). Are BRICS countries pollution
havens? Evidence from a bootstrap ARDL bounds testing approach with a Fourier
function. {it:Sustainable Cities and Society}, 55, 102035.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}
