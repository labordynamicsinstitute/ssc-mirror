{smcl}
{* *! version 1.0.0  20mar2026}{...}
{viewerjumpto "Syntax" "lrmbounds##syntax"}{...}
{viewerjumpto "Description" "lrmbounds##description"}{...}
{viewerjumpto "Options" "lrmbounds##options"}{...}
{viewerjumpto "Methodology" "lrmbounds##methodology"}{...}
{viewerjumpto "Output" "lrmbounds##output"}{...}
{viewerjumpto "Interpretation" "lrmbounds##interpretation"}{...}
{viewerjumpto "Graphs" "lrmbounds##graphs"}{...}
{viewerjumpto "Examples" "lrmbounds##examples"}{...}
{viewerjumpto "Stored Results" "lrmbounds##stored"}{...}
{viewerjumpto "Technical Notes" "lrmbounds##notes"}{...}
{viewerjumpto "References" "lrmbounds##references"}{...}
{viewerjumpto "Author" "lrmbounds##author"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:lrmbounds} {hline 2}}Bounds approach to inference using the long-run multiplier (LRM){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:lrmbounds}
{depvar}
{indepvars}
{ifin}
[{cmd:,}
{it:options}]

{pstd}
{it:depvar} is the dependent variable.  {it:indepvars} are one or more
independent variables.  Data must be {cmd:tsset} before use.  Do NOT apply
{cmd:D.}, {cmd:L.}, or any time-series operators to the variables —
{cmd:lrmbounds} handles all transformations internally.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Lag specification}
{synopt:{opt ardl(numlist)}}ARDL lag orders {it:(p q1 q2 ...)}; first entry is
the lag for {it:depvar} and subsequent entries for each {it:indepvar},
e.g., {cmd:ardl(2 1 3)} gives an ARDL(2,1,3) model{p_end}
{synopt:{opt lags(#)}}uniform lag order for all variables; shorthand for
{cmd:ardl(# # ... #)}{p_end}
{synopt:{opt max:lag(#)}}maximum lag order for information-criterion search;
default is {cmd:4}{p_end}
{synopt:{opt lagsel(string)}}information criterion for automatic lag selection:
{cmd:bic} (default) or {cmd:aic}{p_end}

{syntab:Model specification}
{synopt:{opt trend}}include unrestricted time trend (Case V); default is
unrestricted constant only (Case III){p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt robust}}heteroskedasticity-robust (HC1) standard errors{p_end}
{synopt:{opt bewley}}compute LRMs {it:also} via Bewley (1979) instrumental
variables; the LRM is obtained directly from the IV coefficient with
an asymptotically valid standard error{p_end}

{syntab:Display}
{synopt:{opt nostar:s}}suppress significance stars ({cmd:***}, {cmd:**}, {cmd:*}){p_end}
{synopt:{opt nodiag:nostics}}suppress the diagnostic-test table{p_end}
{synopt:{opt level(#)}}set the confidence level for CIs; default is {cmd:95}{p_end}

{syntab:Graphs}
{synopt:{opt graph}}export six publication-quality PNG graphs{p_end}
{synopt:{opt graphdir(string)}}destination folder for graph files; default is
{cmd:lrmbounds_graphs}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lrmbounds} implements the bounds approach to inference on long-run
relationships proposed by Webb, Linn, and Lebo (2019, 2020).  It provides
a {bf:complete six-step workflow}:

{phang2}
{bf:Step 1.} Estimate the conditional error-correction model (ECM).{p_end}
{phang2}
{bf:Step 2.} Test for a level relationship via the PSS (2001) F-bounds test.{p_end}
{phang2}
{bf:Step 3.} Test the error-correction rate via the PSS t-bounds test.{p_end}
{phang2}
{bf:Step 4.} Classify the equilibrium (non-degenerate vs. degenerate).{p_end}
{phang2}
{bf:Step 5.} Compute LRMs and test each one using the Webb et al. (2019)
critical-value bounds (Tables 3-6).{p_end}
{phang2}
{bf:Step 6.} Run diagnostics and (optionally) produce visualizations.{p_end}

{pstd}
{bf:Why this matters.}  Standard inference on LRMs requires knowing whether
variables are I(0) or I(1), but unit-root tests often give inconsistent
results.  The bounds approach allows valid inference {bf:regardless} of
the (unknown) integration order, at the cost of an area of indeterminacy
where the analyst must acknowledge the uncertainty.

{pstd}
{bf:Key innovation.}  While PSS (2001) bounds test the {it:existence} of a
level relationship, they do not test individual LRMs.  Webb et al. (2019)
derive critical-value bounds for the {it:LRM t-statistic} via 100,000
Monte Carlo replications.  These allow the researcher to test whether each
independent variable has a significant long-run effect on the dependent
variable — without knowing integration orders.


{marker methodology}{...}
{title:Methodology}

{dlgtab:The conditional ECM}

{pstd}
The conditional ECM is specified as (Webb 2019, eq. 5):

{p 8 8 2}
Delta_y_t = c + psi_yy * y_{t-1} + psi_{yx} * x_{t-1} + sum(delta_i * Delta_z_{t-i}) + omega * Delta_x_t + u_t

{pstd}
where {it:psi_yy} is the error-correction rate, {it:psi_{yx}} are coefficients
on the lagged levels of independent variables, and the first-differenced
terms capture short-run dynamics.

{pstd}
The formulation requires {bf:weak exogeneity}: x_t must not respond to the
long-run equilibrium with y_t (PSS Assumption 3).

{dlgtab:PSS F-bounds test}

{pstd}
Tests H0: psi_yy = psi_{yx} = 0 (no level relationship).  Critical values
form bounds:

{phang2}
{bf:I(0) bound} (lower): all regressors are stationary{p_end}
{phang2}
{bf:I(1) bound} (upper): all regressors have unit roots{p_end}

{pstd}
If the F-statistic exceeds the I(1) bound, reject H0 regardless of
integration orders.  If it falls below the I(0) bound, fail to reject.
Between the bounds: inconclusive.

{dlgtab:Degenerate equilibria}

{pstd}
Rejecting the F-test null does NOT guarantee a valid equilibrium.  Webb
(2019, Table 1) classifies four alternatives:

{p2colset 5 12 14 2}{...}
{p2col:{bf:H_A1}}psi_yy = 0, psi_{yx} != 0: {it:Nonsense} — y is a unit root{p_end}
{p2col:{bf:H_A2}}psi_yy != 0, psi_{yx} = 0: {it:Degenerate} — y is independent of x{p_end}
{p2col:{bf:H_A3a}}psi_yy != 0, psi_{yx} != 0: Valid cointegrating equilibrium{p_end}
{p2col:{bf:H_A3b}}psi_yy != 0, psi_{yx} != 0: Valid conditional stationary equilibrium{p_end}
{p2colreset}{...}

{dlgtab:The long-run multiplier}

{pstd}
The LRM for regressor x_j is (Webb 2019, eq. 8):

{p 8 8 2}
theta_j = -psi_{yx,j} / psi_yy

{pstd}
Standard errors are computed via the {bf:delta method} (eq. 12).
With the {opt bewley} option, LRMs are also estimated via the Bewley (1979)
IV regression (eq. 13-14), where x_t in levels is instrumented by Delta_x_t
and Delta_y_t.  The IV coefficient directly gives theta with a valid SE.

{dlgtab:Webb LRM t-bounds test}

{pstd}
{bf:The core innovation of Webb et al. (2019).}

{pstd}
Standard critical values for the LRM t depend on the integration order of
the variables.  Webb et al. derive {bf:bounds} for the LRM t via 100,000
Monte Carlo replications (Tables 3-6).

{pstd}
Decision rule (compare |t_LRM| to the bounds at the chosen alpha):

{phang2}
|t| > Upper Bound: {bf:Significant} — the LRR holds regardless of I(0)/I(1){p_end}
{phang2}
|t| < Lower Bound: {bf:Not significant} — no LRR under any assumption{p_end}
{phang2}
Lower < |t| < Upper: {bf:Inconclusive} — depends on unknown integration order{p_end}


{marker output}{...}
{title:Output Tables}

{pstd}
{cmd:lrmbounds} produces five tables:

{dlgtab:Table 1 — Conditional ECM}

{pstd}
Full coefficient table of the estimated ECM showing:

{phang2}
{bf:Long-run:} Error-correction rate (psi_yy on L.depvar), level coefficients
(psi_{yx} on L.indepvars).{p_end}
{phang2}
{bf:Short-run:} First differences (contemporaneous and lagged).{p_end}

{dlgtab:Table 2 — PSS Bounds Test}

{pstd}
Panel A reports the F-statistic against I(0)/I(1) bounds at 10%, 5%, 1%.{break}
Panel B reports the ECR t-statistic against its bounds.

{dlgtab:Table 3 — Equilibrium Classification}

{pstd}
Classifies the equilibrium type based on the significance patterns of psi_yy
and psi_{yx}, following the taxonomy in Webb (2019, Table 1).

{dlgtab:Table 4 — LRM Bounds Test}

{pstd}
For each regressor reports the LRM, SE, |t|, and the Webb bounds decision.
When {opt bewley} is specified, both delta-method and Bewley IV estimates
appear side by side.

{dlgtab:Table 5 — Diagnostics}

{pstd}
Reports four diagnostic tests:

{phang2}
{bf:Breusch-Godfrey} (lags 1 and 4): serial correlation LM test{p_end}
{phang2}
{bf:Breusch-Pagan}: heteroskedasticity{p_end}
{phang2}
{bf:Ramsey RESET}: functional-form misspecification{p_end}
{phang2}
{bf:Jarque-Bera}: normality of residuals{p_end}


{marker interpretation}{...}
{title:How to Interpret Results}

{dlgtab:Decision procedure}

{pstd}
{bf:1.} Check the {bf:PSS F-test} (Table 2, Panel A):

{phang2}
F > Upper Bound: level relationship exists; proceed to Step 2.{p_end}
{phang2}
Inconclusive or below lower bound: insufficient evidence for an LRR.{p_end}

{pstd}
{bf:2.} Check the {bf:equilibrium classification} (Table 3):

{phang2}
Nondegenerate: LRR is valid; proceed to Step 3.{p_end}
{phang2}
Degenerate: the apparent relationship is spurious or trivial.{p_end}

{pstd}
{bf:3.} Examine the {bf:LRM bounds test} (Table 4):

{phang2}
For each regressor, check |t_LRM| against the Webb bounds.{p_end}
{phang2}
This identifies {it:which} regressors have long-run effects on y.{p_end}

{pstd}
{bf:4.} Check the {bf:diagnostics} (Table 5) for model adequacy.

{dlgtab:What the bounds mean}

{pstd}
Webb et al. (2020) show that using standard normal critical values for
LRM t-tests can {bf:over-reject} the null when variables contain unit roots.
The t-distribution of the LRM shifts to the right under I(1) DGPs:

{phang2}
Under I(0): standard critical values are correct = lower bound{p_end}
{phang2}
Under I(1): standard values are too liberal = upper bound{p_end}
{phang2}
Under uncertainty: truth lies between = area of indeterminacy{p_end}

{pstd}
The area of indeterminacy is a {bf:feature}, not a bug.  It honestly
reflects the analyst's uncertainty about integration orders.

{dlgtab:Common pitfalls}

{pstd}
{bf:1.} Do NOT use the GECM simply because it is "algebraically equivalent"
to the ADL.  The equivalence holds mechanically; inference rules differ with
I(0) vs. I(1) data.

{pstd}
{bf:2.} Do NOT rely solely on the PSS F-test.  Even after rejecting the null,
check for degenerate equilibria before interpreting LRMs.

{pstd}
{bf:3.} Do NOT use standard t-critical values for LRM inference when unit-root
tests are ambiguous.  Use the Webb bounds instead.

{pstd}
{bf:4.} The Bewley IV estimator is asymptotically equivalent to the delta
method but can differ in finite samples.  When both are available, compare
them as a robustness check.


{marker graphs}{...}
{title:Graphs}

{pstd}
With {opt graph}, six publication-quality PNG files are exported:

{p2colset 5 38 40 2}{...}
{p2col:{bf:File}}{bf:Description}{p_end}
{p2line}
{p2col:lrm_forest_plot.png}LRM point estimates with 95% CI for all regressors{p_end}
{p2col:pss_fbounds.png}F-statistic plotted against I(0)/I(1) bounds with colored acceptance/rejection zones{p_end}
{p2col:actual_vs_fitted.png}Time series of actual vs. ECM-fitted values{p_end}
{p2col:residual_diagnostics.png}Three-panel residual analysis: time series, histogram with kernel density, QQ plot{p_end}
{p2col:cusum_stability.png}CUSUM test with 5% significance bands{p_end}
{p2col:dynamic_multipliers.png}Cumulative dynamic multiplier paths{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1: Basic usage}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv}{p_end}

{pstd}
Estimates ARDL model with automatic BIC lag selection, Case III (constant only).
Produces Tables 1-5 and a summary box.

{pstd}{bf:Example 2: ARDL(2,1,3) lag specification}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, ardl(2 1 3)}{p_end}

{pstd}
Specifies 2 lags for the dependent variable, 1 lag for ln_inc, and 3 lags
for ln_inv.  This mimics the notation used in the original ARDL literature.

{pstd}{bf:Example 3: With Bewley IV and time trend}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, bewley trend}{p_end}

{pstd}
Adds unrestricted time trend (Case V).  Table 4 displays both delta-method
and Bewley IV estimates side by side.  The Bewley IV gives independent SE
estimates that serve as a robustness check.

{pstd}{bf:Example 4: Uniform lag order}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, lags(2)}{p_end}

{pstd}
Sets lag order to 2 for all variables: equivalent to {cmd:ardl(2 2 2)}.

{pstd}{bf:Example 5: AIC lag selection with maxlag 8}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, maxlag(8) lagsel(aic)}{p_end}

{pstd}
Searches lag orders from 1 to 8 using the Akaike information criterion
instead of the default BIC.

{pstd}{bf:Example 6: Robust SEs with all visualizations}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, robust bewley graph}{p_end}

{pstd}
HC1 robust standard errors.  Six graphs exported to {cmd:lrmbounds_graphs/}.

{pstd}{bf:Example 7: Custom graph directory}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, graph graphdir("results/figs")}{p_end}

{pstd}{bf:Example 8: Bivariate case}

{phang2}{cmd:. lrmbounds ln_consump ln_inc, bewley trend graph}{p_end}

{pstd}
Single regressor.  Webb bounds are applied to the single LRM.

{pstd}{bf:Example 9: Accessing stored results}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, bewley}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. display "F-test: " r(F_pss)}{p_end}
{phang2}{cmd:. display "LRM(income): " r(lrm_1) " |t| = " abs(r(lrm_t_1))}{p_end}
{phang2}{cmd:. display "Decision: " r(lrm_dcode_1)}{p_end}

{pstd}{bf:Example 10: Suppress diagnostics and stars}

{phang2}{cmd:. lrmbounds ln_consump ln_inc ln_inv, nodiagnostics nostars}{p_end}


{marker stored}{...}
{title:Stored Results}

{pstd}
{cmd:lrmbounds} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of independent variables{p_end}
{synopt:{cmd:r(optlag)}}selected lag order for dependent variable{p_end}
{synopt:{cmd:r(r2)}}R-squared{p_end}
{synopt:{cmd:r(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:r(rmse)}}root mean squared error{p_end}
{synopt:{cmd:r(ll)}}log-likelihood{p_end}
{synopt:{cmd:r(ecr)}}error-correction rate (psi_yy){p_end}
{synopt:{cmd:r(ecr_se)}}standard error of ECR{p_end}
{synopt:{cmd:r(ecr_t)}}t-statistic of ECR{p_end}
{synopt:{cmd:r(F_pss)}}PSS F-statistic{p_end}
{synopt:{cmd:r(f_lb_5)}}F-bounds lower bound at 5%{p_end}
{synopt:{cmd:r(f_ub_5)}}F-bounds upper bound at 5%{p_end}
{synopt:{cmd:r(cv_lb_5)}}Webb LRM t-bounds lower bound at 5%{p_end}
{synopt:{cmd:r(cv_ub_5)}}Webb LRM t-bounds upper bound at 5%{p_end}
{synopt:{cmd:r(lrm_}{it:j}{cmd:)}}LRM for j-th regressor (delta method){p_end}
{synopt:{cmd:r(lrm_se_}{it:j}{cmd:)}}standard error of j-th LRM{p_end}
{synopt:{cmd:r(lrm_t_}{it:j}{cmd:)}}t-statistic of j-th LRM{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable names{p_end}
{synopt:{cmd:r(f_decision)}}F-bounds test decision text{p_end}
{synopt:{cmd:r(f_dcode)}}F-bounds decision code: {cmd:reject}, {cmd:inconclusive}, or {cmd:fail}{p_end}
{synopt:{cmd:r(equil_type)}}equilibrium classification text{p_end}
{synopt:{cmd:r(equil_code)}}equilibrium code: {cmd:valid}, {cmd:nonsense}, {cmd:degenerate}, or {cmd:na}{p_end}
{synopt:{cmd:r(lrm_decision_}{it:j}{cmd:)}}LRM bounds decision for j-th regressor{p_end}
{synopt:{cmd:r(lrm_dcode_}{it:j}{cmd:)}}LRM decision code: {cmd:reject}, {cmd:inconclusive}, or {cmd:fail}{p_end}


{marker notes}{...}
{title:Technical Notes}

{pstd}
{bf:1. Lag selection.}  When neither {opt ardl()} nor {opt lags()} is
specified, {cmd:lrmbounds} searches over uniform lag orders from 1 to
{opt maxlag()} using BIC (default) or AIC.  With {opt ardl()}, the user
can set different lag orders for each variable, following the standard
ARDL(p, q1, q2, ...) notation.

{pstd}
{bf:2. Critical values.}  F-bounds and ECR t-bounds from Pesaran, Shin, and
Smith (2001, Tables CI-CII).  LRM t-bounds from Webb, Linn, and Lebo
(2019, Tables 3-6).  Small-sample adjustments based on Narayan (2005).

{pstd}
{bf:3. Bewley IV.}  The Bewley (1979) regression estimates the LRM directly
by instrumenting x_t in levels with Delta_x_t and Delta_y_t.  This gives
an independent SE estimate that does not rely on the delta method.  When
both are available, comparing them serves as a specification check.

{pstd}
{bf:4. Delta method.}  LRM = -psi_{yx}/psi_yy.  The variance is computed
using the gradient vector g = (-1/psi_yy, psi_{yx}/psi_yy^2) applied to
the OLS variance-covariance matrix.

{pstd}
{bf:5. Degenerate equilibria.}  Even when the PSS F-test rejects the null,
the relationship can take four forms (Webb 2019, Table 1).  Only H_A3
(nondegenerate) represents a valid long-run relationship.  {cmd:lrmbounds}
automatically classifies the equilibrium type.

{pstd}
{bf:6. Diagnostics.}  Breusch-Godfrey uses the auxiliary regression of OLS
residuals on all regressors plus lagged residuals (LM test).  Breusch-Pagan
regresses normalized squared residuals on the regressors.  Ramsey RESET 
adds powers of fitted values.  Jarque-Bera tests skewness and kurtosis.

{pstd}
{bf:7. Deterministic specification.}  Case III (default) includes an
unrestricted constant; Case V ({opt trend}) adds an unrestricted time trend.
The appropriate critical values are selected automatically.

{pstd}
{bf:8. Software requirements.}  Stata 14.0 or later.  No external
dependencies; all critical values are hardcoded from the original tables.


{marker references}{...}
{title:References}

{phang}
Bewley, R. 1979. The direct estimation of the equilibrium response in a
linear dynamic model. {it:Economics Letters} 3: 357-361.{p_end}

{phang}
De Boef, S. and L. Keele. 2008. Taking time seriously.
{it:American Journal of Political Science} 52(1): 184-200.{p_end}

{phang}
Enns, P.K., N.J. Kelly, T. Masaki, and P.C. Wohlfarth. 2016. Don't jettison
the general error correction model just yet.
{it:Research & Politics} 3(2): 1-16.{p_end}

{phang}
Grant, T. and M.J. Lebo. 2016. Error correction methods with political time
series.  {it:Political Analysis} 24(1): 3-30.{p_end}

{phang}
Keele, L., S. Linn, and C.M. Webb. 2016. Treating time with all due
seriousness.  {it:Political Analysis} 24(1): 31-41.{p_end}

{phang}
Narayan, P.K. 2005. The saving and investment nexus for China: Evidence from
cointegration tests. {it:Applied Economics} 37(17): 1979-1990.{p_end}

{phang}
Pesaran, M.H. and Y. Shin. 1998. An autoregressive distributed-lag modelling
approach to cointegration analysis. In S. Strom (ed.),
{it:Econometrics and Economic Theory in the 20th Century: The Ragnar Frisch
Centennial Symposium}. Cambridge University Press.{p_end}

{phang}
Pesaran, M.H., Y. Shin, and R.J. Smith. 2001. Bounds testing approaches to
the analysis of level relationships.
{it:Journal of Applied Econometrics} 16(3): 289-326.{p_end}

{phang}
Philips, A.Q. 2018. Have your cake and eat it too?  Cointegration and dynamic
inference from autoregressive distributed lag models.
{it:American Journal of Political Science} 62(1): 230-244.{p_end}

{phang}
Webb, C.M., S. Linn, and M.J. Lebo. 2019. A bounds approach to inference
using the long run multiplier.
{it:Political Analysis} 27(3): 281-301.{p_end}

{phang}
Webb, C.M., S. Linn, and M.J. Lebo. 2020. Beyond the unit root question:
Uncertainty and inference in time series models.
{it:Journal of Politics}.{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr. Merwan Roudane{p_end}
{pstd}Email: merwanroudane920@gmail.com{p_end}

{pstd}
{bf:Version:} 1.0.0 (20 March 2026){p_end}

{pstd}
{bf:Suggested citation:}{p_end}
{phang}
Roudane, M.  2026.  LRMBOUNDS: Stata module for the bounds approach to
inference using the long-run multiplier.  Statistical Software Components,
Boston College Department of Economics.{p_end}

{pstd}
{bf:Based on:}{p_end}
{phang}
Webb, C.M., S. Linn, and M.J. Lebo. 2019. A bounds approach to inference
using the long run multiplier.
{it:Political Analysis} 27(3): 281-301.{p_end}
{phang}
Webb, C.M., S. Linn, and M.J. Lebo. 2020. Beyond the unit root question:
Uncertainty and inference in time series models.
{it:Journal of Politics}.{p_end}
