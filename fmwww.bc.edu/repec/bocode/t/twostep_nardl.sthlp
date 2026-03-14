{smcl}
{* *! twostep_nardl.sthlp version 3.0.0  09mar2026}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "ardlbounds" "help ardlbounds"}{...}
{vieweralsosee "nardl" "help nardl"}{...}
{viewerjumpto "Syntax" "twostep_nardl##syntax"}{...}
{viewerjumpto "Description" "twostep_nardl##description"}{...}
{viewerjumpto "Options" "twostep_nardl##options"}{...}
{viewerjumpto "Post-estimation" "twostep_nardl##postestimation"}{...}
{viewerjumpto "Interpretation guide" "twostep_nardl##interpretation"}{...}
{viewerjumpto "Examples" "twostep_nardl##examples"}{...}
{viewerjumpto "Stored results" "twostep_nardl##results"}{...}
{viewerjumpto "Requirements" "twostep_nardl##requirements"}{...}
{viewerjumpto "References" "twostep_nardl##references"}{...}
{viewerjumpto "Authors" "twostep_nardl##authors"}{...}
{viewerjumpto "Also see" "twostep_nardl##alsosee"}{...}

{title:Title}

{p2colset 5 26 28 2}{...}
{p2col:{bf:twostep_nardl} {hline 2}}Two-step estimation of the Nonlinear
Autoregressive Distributed Lag (NARDL) model with comprehensive
post-estimation analysis{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:twostep_nardl}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt de:compose(varlist)}}variables to decompose into positive/negative partial sums (required){p_end}
{synopt:{opt la:gs(numlist)}}lag structure for each variable; default is {cmd:lags(4)}{p_end}
{synopt:{opt maxl:ags(numlist)}}maximum lag for automatic selection{p_end}
{synopt:{opt aic}}use AIC for lag selection{p_end}
{synopt:{opt bic}}use BIC for lag selection (default when {opt maxlags()} specified){p_end}
{synopt:{opt onestep}}use one-step OLS estimation (alternative to two-step){p_end}
{synopt:{opt step1(method)}}first-step estimator: {cmd:fmols} (default), {cmd:ols}, {cmd:tols}, {cmd:fmtols}{p_end}
{synopt:{opt thresh:old(numlist)}}threshold for decomposition; default is 0{p_end}
{synopt:{opt bw:idth(#)}}HAC bandwidth; default is floor(T^(1/4)){p_end}

{syntab:Deterministics}
{synopt:{opt nocon:stant}}suppress constant (Case 1){p_end}
{synopt:{opt trendvar(varname)}}include a time trend (Case 4/5){p_end}
{synopt:{opt res:tricted}}restrict deterministic terms to LR relationship{p_end}
{synopt:{opt exog(varlist)}}exogenous regressors{p_end}

{syntab:Reporting}
{synopt:{opt noct:able}}suppress coefficient table{p_end}
{synopt:{opt nohe:ader}}suppress header{p_end}
{synopt:{opt nowald:test}}suppress Wald test display{p_end}
{synopt:{opt do:ts}}display lag selection progress{p_end}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}
{cmd:tsset} must be set before using {cmd:twostep_nardl}.{p_end}
{p 4 6 2}
Time-series operators are allowed for {depvar} and {indepvars}.{p_end}
{p 4 6 2}
Data must be time-series (not panel).{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:twostep_nardl} implements the two-step estimation framework for the
Nonlinear Autoregressive Distributed Lag (NARDL) model developed by
{help twostep_nardl##CGS2019:Cho, Greenwood-Nimmo, and Shin (2019)}.

{pstd}
The NARDL model ({help twostep_nardl##SYG2014:Shin, Yu, and Greenwood-Nimmo, 2014})
is an asymmetric extension of the ARDL model of
{help twostep_nardl##PSS2001:Pesaran, Shin, and Smith (2001)}. It decomposes
changes in independent variables into positive and negative partial sums,
allowing separate long-run and short-run coefficients for increases vs. decreases.

{pstd}
{bf:The NARDL Error Correction Model:}

{p 8 8 2}
Delta_y_t = rho * y_{t-1} + theta+ * x+_{t-1} + theta- * x-_{t-1}
+ sum(phi_j * Delta_y_{t-j}) + sum(pi+_j * Delta_x+_{t-j})
+ sum(pi-_j * Delta_x-_{t-j}) + u_t

{pstd}
where x+_t = sum(max(Delta_x_s, 0)) and x-_t = sum(min(Delta_x_s, 0)) are
partial sum decompositions, rho is the speed of adjustment, and the long-run
multipliers are beta+ = -theta+/rho and beta- = -theta-/rho.

{pstd}
{bf:Linear (non-decomposed) variables:}

{pstd}
Independent variables listed in {it:indepvars} but not in {opt decompose()}
are treated as linear variables. They enter the long-run equation in levels
and the short-run equation in first differences, without partial sum
decomposition. This allows mixing asymmetric and symmetric regressors in a
single model:

{pstd}
{bf:Why two-step?} The single-step OLS estimator of the NARDL model suffers
from an asymptotic singularity problem that impedes the development of
standard asymptotic theory. The two-step procedure addresses this:

{phang2}
{bf:Step 1 (Long-run):} Estimates parameters of the reparameterized long-run
cointegrating relationship using FM-OLS
({help twostep_nardl##PH1990:Phillips and Hansen, 1990}) for k=1 or FM-TOLS
for k>1. These estimators are robust to endogeneity and serial correlation
and have mixed normal limiting distributions.{p_end}

{phang2}
{bf:Step 2 (Short-run):} Constructs the error correction term (ECT) from
Step 1 and estimates the ECM by OLS. Due to super-consistency of the
Step 1 estimator, treating the ECT as known does not affect the
asymptotic distribution of the Step 2 estimator.{p_end}

{pstd}
The command also supports the standard {bf:one-step OLS} approach
(Shin, Yu, and Greenwood-Nimmo, 2014) via the {opt onestep} option.
In one-step, the NARDL model is estimated by unrestricted OLS and long-run
coefficients are derived using the delta method via {cmd:nlcom}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(numlist)} specifies the lag structure. A single value applies to
all variables. Multiple values must match the number of variables (depvar
first, then each indepvar). Values of {cmd:.} trigger automatic lag
selection for that variable.{p_end}

{phang}
{opt maxlags(numlist)} sets the maximum lag for automatic selection. When
specified without {opt lags()}, all variables undergo automatic lag selection.{p_end}

{phang}
{opt method(string)} specifies the estimation method.
{cmd:twostep} (default) uses the two-step procedure.
{cmd:onestep} uses single-equation OLS with delta-method long-run coefficients.{p_end}

{phang}
{opt step1(method)} specifies the first-step estimator (two-step only).
{cmd:fmols} — Fully-Modified OLS (default for k=1).
{cmd:ols} — standard OLS (for comparison).
{cmd:fmtols} — Fully-Modified Transformed OLS (default for k>1).
{cmd:tols} — Transformed OLS.
FM-OLS and FM-TOLS are recommended as they correct for endogeneity and
serial correlation.{p_end}

{phang}
{opt decompose(varlist)} specifies which independent variables are decomposed
into positive and negative partial sums. This option is required.
Variables listed in {it:indepvars} but not in {opt decompose()} are treated as
linear variables — they enter the long-run equation in levels and the
short-run equation in first differences, without decomposition.{p_end}

{phang}
{opt threshold(numlist)} specifies the threshold value for decomposition.
Default is 0 (positive = increases, negative = decreases). Non-zero thresholds
create dead bands: only changes exceeding the threshold are classified.{p_end}

{phang}
{opt bwidth(#)} specifies the bandwidth for the Newey-West HAC
estimator used in FM-OLS/FM-TOLS.
Default is floor(T^{1/4}).{p_end}

{dlgtab:Deterministics}

{phang}
{opt noconstant} suppresses the constant (Case 1). Not recommended unless
theory dictates.{p_end}

{phang}
{opt trendvar(varname)} includes a time trend. Without {opt restricted},
this gives Case 5 (unrestricted trend). With {opt restricted}, Case 4
(trend restricted to LR relationship).{p_end}

{phang}
{opt restricted} restricts the constant (Case 2) or trend (Case 4) to the
long-run relationship.{p_end}

{phang}
{opt exog(varlist)} includes additional exogenous regressors in the
short-run dynamic equation.{p_end}

{dlgtab:Deterministic cases (PSS framework)}

{p 8 8 2}
The five cases follow
{help twostep_nardl##PSS2001:Pesaran, Shin, and Smith (2001)}:

{phang2}{bf:Case 1:} No intercept, no trend ({opt noconstant}){p_end}
{phang2}{bf:Case 2:} Restricted intercept, no trend ({opt restricted}){p_end}
{phang2}{bf:Case 3:} Unrestricted intercept, no trend (default){p_end}
{phang2}{bf:Case 4:} Unrestricted intercept, restricted trend ({opt trendvar() restricted}){p_end}
{phang2}{bf:Case 5:} Unrestricted intercept, unrestricted trend ({opt trendvar()}){p_end}


{marker postestimation}{...}
{title:Post-estimation commands}

{pstd}The following commands are available after {cmd:twostep_nardl}:

{synoptset 32}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{synopt:{helpb twostep_nardl##ectest:estat ectest}}PSS bounds test for cointegration{p_end}
{synopt:{helpb twostep_nardl##waldtest:estat waldtest}}Wald tests for LR and SR symmetry{p_end}
{synopt:{helpb twostep_nardl##diagnostics:estat diagnostics}}residual diagnostics panel{p_end}
{synopt:{helpb twostep_nardl##multiplier:estat multiplier}}cumulative dynamic multipliers{p_end}
{synopt:{helpb twostep_nardl##halflife:estat halflife}}half-life and persistence profile{p_end}
{synopt:{helpb twostep_nardl##asymadj:estat asymadj}}asymmetric adjustment speed{p_end}
{synopt:{helpb twostep_nardl##irf:estat irf}}impulse response functions{p_end}
{synopt:{helpb twostep_nardl##ecmtable:estat ecmtable}}paper-style parameter estimates table (CGS 2019){p_end}
{synopt:{helpb twostep_nardl##predict:predict}}fitted values, residuals, ECT{p_end}
{synoptline}

{marker ecmtable}{...}
{dlgtab:estat ecmtable}

{pstd}
{cmd:estat ecmtable}

{pstd}
Displays the estimated ECM parameters in the publication-style format of
Table 9 in {help twostep_nardl##CGS2019:Cho, Greenwood-Nimmo, and Shin (2019)}.
The output contains two panels:

{phang2}{bf:Panel A: Long-Run Estimates} — Long-run multipliers (beta+, beta-)
with standard errors and t-statistics from the FM-OLS (two-step) or
delta-method (one-step) VCE.{p_end}

{phang2}{bf:Panel B: Short-Run Dynamic Estimates} — ECM coefficient plus all
lagged differences with standard errors and t-statistics.  For two-step,
the first row is ECM(t-1); for one-step, the level variables (y_{t-1},
x+_{t-1}, x-_{t-1}) are shown.{p_end}

{pstd}
A diagnostics footer reports Adjusted R-squared, RMSE, F-statistic,
number of observations, and a normality test p-value.

{marker ectest}{...}
{dlgtab:estat ectest}

{pstd}
{cmd:estat ectest} [{cmd:,} {opt sig:levels(numlist)} {opt asy:mptotic}]

{pstd}
Performs the {help twostep_nardl##PSS2001:Pesaran, Shin, and Smith (2001)}
bounds test for the existence of a level (cointegrating) relationship.
Reports both the F-statistic (PSS) for joint significance of the level
variables and the t-statistic (BDM) on the speed of adjustment coefficient.

{pstd}
If the {cmd:ardl} package is installed, finite-sample critical values and
approximate p-values from
{help twostep_nardl##KS2020:Kripfganz and Schneider (2020)} are displayed
along with a decision matrix: {bf:.a} = no rejection, {bf:.} = inconclusive,
{bf:.r} = rejection.

{pstd}
{bf:Decision rule:} Reject H0 (no cointegration) if both F and t exceed
their I(1) critical values. Do not reject if either statistic is closer
to zero than the I(0) critical value. Otherwise, the result is inconclusive.

{pstd}
Options:

{phang}{opt siglevels(numlist)} significance levels for critical values
(default: 10 5 1).{p_end}
{phang}{opt asymptotic} use asymptotic instead of finite-sample critical values.{p_end}

{marker waldtest}{...}
{dlgtab:estat waldtest}

{pstd}
{cmd:estat waldtest} [{cmd:,} {opt lr:symmetry} {opt sr:symmetry} {opt imp:act}
{opt pair:wise} {opt all}]

{pstd}
Tests for asymmetry in the long-run and short-run coefficients:

{phang2}{bf:Long-run symmetry:} H0: beta+ = beta-, tested using delta-method
VCE for two-step or nlcom VCE for one-step.{p_end}
{phang2}{bf:Short-run symmetry (additive):} H0: sum(pi+_j) = sum(pi-_j),
tested using robust (HC) standard errors.{p_end}
{phang2}{bf:Short-run symmetry (impact):} H0: pi+_0 = pi-_0, the
contemporaneous impact.{p_end}

{marker diagnostics}{...}
{dlgtab:estat diagnostics}

{pstd}
{cmd:estat diagnostics} [{cmd:,} {opt gr:aph}]

{pstd}
Residual diagnostic panel:

{phang2}{bf:Serial correlation:} Breusch-Godfrey LM test.{p_end}
{phang2}{bf:Heteroskedasticity:} White's test.{p_end}
{phang2}{bf:Normality:} Skewness-kurtosis test.{p_end}
{phang2}{bf:Functional form:} Ramsey RESET test.{p_end}

{pstd}
With {opt graph}, a CUSUM stability plot is produced.

{pstd}
{bf:Note:} Rejection of diagnostic tests indicates potential model
misspecification. Non-rejection supports the validity of OLS inference.

{marker multiplier}{...}
{dlgtab:estat multiplier}

{pstd}
{cmd:estat multiplier} [{cmd:,} {opt hor:izon(#)} {opt gr:aph} {opt notable}
{opt sav:ing(filename)} {opt pos:color(color)} {opt neg:color(color)}
{opt asym:color(color)} {opt sch:eme(scheme)} {opt ti:tle(string)}]

{pstd}
Computes cumulative dynamic multipliers showing how the dependent variable
adjusts over time to a unit positive or negative shock. The cumulative
multipliers converge to the long-run coefficients beta+ and beta-.

{pstd}
The difference between positive and negative multiplier paths reveals the
adjustment asymmetry pattern. With {opt graph}, a publication-quality
plot is produced showing positive, negative, and asymmetry paths.

{phang}{opt horizon(#)} number of periods; default is 40.{p_end}

{marker halflife}{...}
{dlgtab:estat halflife}

{pstd}
{cmd:estat halflife} [{cmd:,} {opt hor:izon(#)} {opt gr:aph}]

{pstd}
Reports:

{phang2}{bf:A. ECM Half-Life:} Based on the speed of adjustment coefficient
rho. The half-life is -ln(2)/ln(1+rho), the number of periods to correct
50% of a disequilibrium shock.{p_end}

{phang2}{bf:B. Persistence Profile}
({help twostep_nardl##PS1996:Pesaran and Shin, 1996}):
Shows the full convergence path from 100% disequilibrium to 0%.
More informative than the simple half-life because it captures
non-monotonic convergence patterns from higher-order AR dynamics.{p_end}

{pstd}
{bf:Warning:} If rho >= 0, the ECM is NOT convergent and no half-life exists.

{marker asymadj}{...}
{dlgtab:estat asymadj}

{pstd}
{cmd:estat asymadj} [{cmd:,} {opt hor:izon(#)} {opt gr:aph}]

{pstd}
Compares the adjustment speed for positive vs. negative shocks. Reports
impact multipliers, effective long-run values, half-lives for each direction,
and whether adjustment is faster for increases or decreases.

{marker irf}{...}
{dlgtab:estat irf}

{pstd}
{cmd:estat irf} [{cmd:,} {opt hor:izon(#)} {opt gr:aph}]

{pstd}
Impulse response functions for positive and negative shocks, showing both
period-by-period responses and cumulative effects.

{marker predict}{...}
{dlgtab:predict}

{pstd}
{cmd:predict} [{it:type}] {newvar} [{cmd:,} {opt xb} {opt resid:uals} {opt ect:erm}]

{pstd}
Options:

{phang}{opt xb} fitted values from the ECM (default).{p_end}
{phang}{opt residuals} residuals from the ECM.{p_end}
{phang}{opt ecterm} error correction term.{p_end}


{marker interpretation}{...}
{title:Interpretation guide}

{dlgtab:Speed of adjustment (rho)}

{pstd}
The ECM coefficient rho (coefficient on L.ect in ADJ equation) should be:

{phang2}• {bf:Negative and significant}: indicates valid error correction
(convergence to long-run equilibrium).{p_end}
{phang2}• {bf:Between -1 and 0}: monotonic convergence (most common).{p_end}
{phang2}• {bf:Less than -1}: oscillatory convergence (overshooting).{p_end}
{phang2}• {bf:Non-negative}: no error correction — the model is misspecified or
there is no cointegrating relationship.{p_end}

{dlgtab:Long-run coefficients (beta+, beta-)}

{pstd}
These measure the equilibrium effect of a permanent unit increase (beta+)
or decrease (beta-) in x on y. If beta+ != beta- (Wald test rejects), the
long-run relationship is asymmetric. Example: if beta+ = 0.8 and beta- = 0.3,
a permanent unit increase in x raises y by 0.8, but a unit decrease only
lowers y by 0.3.

{dlgtab:Short-run coefficients}

{pstd}
The pi+ and pi- coefficients capture the immediate and lagged dynamic
responses to positive and negative shocks. Impact asymmetry (pi+_0 != pi-_0)
means that the initial response to increases differs from decreases.
Additive asymmetry (sum pi+ != sum pi-) captures overall short-run asymmetry.

{dlgtab:Bounds test interpretation}

{pstd}
The PSS bounds test has three possible outcomes at each significance level:

{phang2}• {bf:Reject (.r):} Both F and t statistics exceed I(1) bounds.
Evidence of cointegration regardless of integration order.{p_end}
{phang2}• {bf:No rejection (.a):} Either statistic falls below I(0) bounds.
No evidence of cointegration.{p_end}
{phang2}• {bf:Inconclusive (.):} Statistics between I(0) and I(1) bounds.
Further testing (e.g., unit root tests) needed.{p_end}

{dlgtab:Dynamic multipliers}

{pstd}
Cumulative dynamic multipliers show the time path of adjustment to a unit
shock. They converge to the long-run coefficients. The difference between
positive and negative paths shows how much and how long asymmetry persists.

{dlgtab:Persistence profile}

{pstd}
PP(h) starts at 1.0 (full disequilibrium) and converges to 0 (equilibrium).
The half-life from the persistence profile may differ from the simple
ECM half-life when there are higher-order AR dynamics.

{dlgtab:Recommended workflow}

{phang2}1. Verify variables are I(0) or I(1) (unit root tests).{p_end}
{phang2}2. Estimate with {cmd:twostep_nardl}.{p_end}
{phang2}3. Run {cmd:estat ectest}: bounds test for cointegration.{p_end}
{phang2}4. Check rho is negative and significant.{p_end}
{phang2}5. Run {cmd:estat diagnostics}: verify no serial correlation, normality, etc.{p_end}
{phang2}6. Run {cmd:estat waldtest}: test for LR and SR asymmetry.{p_end}
{phang2}7. Run {cmd:estat multiplier, graph}: visualize adjustment paths.{p_end}
{phang2}8. Run {cmd:estat halflife, graph}: assess convergence speed.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1: Two-step NARDL with FMOLS (recommended)}{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. twostep_nardl ln_consump ln_inc, decompose(ln_inc) lags(4 4) step1(fmols)}{p_end}

{pstd}{bf:Example 2: One-step NARDL (SYG 2014 approach)}{p_end}
{phang2}{cmd:. twostep_nardl ln_consump ln_inc, decompose(ln_inc) lags(4 4) onestep}{p_end}

{pstd}{bf:Example 3: Automatic lag selection (BIC)}{p_end}
{phang2}{cmd:. twostep_nardl ln_consump ln_inc, decompose(ln_inc) maxlags(6) bic dots}{p_end}

{pstd}{bf:Example 4: Mixed model — asymmetric income, linear investment}{p_end}
{phang2}{cmd:. twostep_nardl ln_consump ln_inc ln_inv, decompose(ln_inc) lags(4 4 4) step1(fmols)}{p_end}
{phang2}{cmd:. * ln_inc is decomposed; ln_inv enters as a linear variable}{p_end}

{pstd}{bf:Example 5: Bounds test for cointegration}{p_end}
{phang2}{cmd:. estat ectest}{p_end}

{pstd}{bf:Example 6: Full post-estimation analysis}{p_end}
{phang2}{cmd:. estat waldtest, all}{p_end}
{phang2}{cmd:. estat diagnostics, graph}{p_end}
{phang2}{cmd:. estat multiplier, horizon(30) graph}{p_end}
{phang2}{cmd:. estat halflife, horizon(30) graph}{p_end}
{phang2}{cmd:. estat asymadj, horizon(30) graph}{p_end}
{phang2}{cmd:. estat irf, horizon(20) graph}{p_end}

{pstd}{bf:Example 7: Predictions}{p_end}
{phang2}{cmd:. predict double yhat, xb}{p_end}
{phang2}{cmd:. predict double resid, residuals}{p_end}
{phang2}{cmd:. predict double ect, ecterm}{p_end}

{pstd}{bf:Example 8: Custom threshold (asymmetric dead band)}{p_end}
{phang2}{cmd:. twostep_nardl y x, decompose(x) lags(4) threshold(0.05)}{p_end}

{pstd}{bf:Example 9: Case 5 with trend}{p_end}
{phang2}{cmd:. twostep_nardl ln_consump ln_inc, decompose(ln_inc) lags(4 4) trendvar(qtr)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:twostep_nardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(r2)}}R-squared (step 2 / ECM){p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(F)}}model F-statistic{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}
{synopt:{cmd:e(tau2)}}long-run variance (step 1){p_end}
{synopt:{cmd:e(rho)}}speed of adjustment coefficient{p_end}
{synopt:{cmd:e(t_bdm)}}BDM t-statistic on rho{p_end}
{synopt:{cmd:e(F_pss)}}PSS F-statistic for bounds test{p_end}
{synopt:{cmd:e(case)}}deterministic case (1-5){p_end}
{synopt:{cmd:e(k)}}number of decomposed (asymmetric) variables{p_end}
{synopt:{cmd:e(k_lin)}}number of linear (non-decomposed) variables{p_end}
{synopt:{cmd:e(p_lag)}}lag order for dependent variable (in differences){p_end}
{synopt:{cmd:e(q_lag)}}maximum lag order for x variables{p_end}
{synopt:{cmd:e(W_lr)}}LR symmetry Wald statistic{p_end}
{synopt:{cmd:e(p_lr)}}LR symmetry p-value{p_end}
{synopt:{cmd:e(W_sr)}}SR additive symmetry Wald statistic{p_end}
{synopt:{cmd:e(p_sr)}}SR additive symmetry p-value{p_end}
{synopt:{cmd:e(W_impact)}}impact symmetry Wald statistic{p_end}
{synopt:{cmd:e(p_impact)}}impact symmetry p-value{p_end}
{synopt:{cmd:e(lagselect)}}1 if automatic lag selection was used{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:twostep_nardl}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(xvars)}}independent variable(s){p_end}
{synopt:{cmd:e(asymvars)}}decomposed (asymmetric) variable(s){p_end}
{synopt:{cmd:e(linvars)}}linear (non-decomposed) variable(s){p_end}
{synopt:{cmd:e(method)}}{cmd:twostep} or {cmd:onestep}{p_end}
{synopt:{cmd:e(step1)}}first-step method (twostep only){p_end}
{synopt:{cmd:e(step1_label)}}display label for step 1{p_end}
{synopt:{cmd:e(lagstructure)}}lag structure string{p_end}
{synopt:{cmd:e(pos_vars)}}positive partial sum variable names{p_end}
{synopt:{cmd:e(neg_vars)}}negative partial sum variable names{p_end}
{synopt:{cmd:e(ect_var)}}ECT variable name{p_end}
{synopt:{cmd:e(trendvar)}}trend variable (if used){p_end}
{synopt:{cmd:e(exogvars)}}exogenous variables (if used){p_end}
{synopt:{cmd:e(predict)}}{cmd:twostep_nardl_p}{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:twostep_nardl_estat}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}combined coefficient vector [ADJ | LR | SR]{p_end}
{synopt:{cmd:e(V)}}combined variance-covariance matrix{p_end}
{synopt:{cmd:e(b_lr)}}long-run coefficients for decomposed vars (beta+, beta-){p_end}
{synopt:{cmd:e(V_lr)}}long-run VCE for decomposed vars{p_end}
{synopt:{cmd:e(b_lin)}}long-run coefficients for linear vars (if any){p_end}
{synopt:{cmd:e(V_lin)}}long-run VCE for linear vars (if any){p_end}
{synopt:{cmd:e(b_sr)}}short-run coefficients (from OLS){p_end}
{synopt:{cmd:e(V_sr)}}short-run VCE{p_end}
{synopt:{cmd:e(lags)}}selected lag structure{p_end}
{synopt:{cmd:e(maxlags)}}maximum lag limits{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker requirements}{...}
{title:Requirements}

{pstd}
{bf:Stata version:} 14 or later.

{pstd}
{bf:Required:} Time-series data with {cmd:tsset}.

{pstd}
{bf:Recommended packages:}

{phang2}
{cmd:ardl} — Required for {cmd:estat ectest} to display Kripfganz-Schneider
finite-sample critical values. Install with: {cmd:ssc install ardl}{p_end}

{pstd}
{bf:Data requirements:}

{phang2}• Variables should be I(0) or I(1). The ARDL/NARDL bounds test is
invalid if any variable is I(2).{p_end}
{phang2}• Sufficient observations for the chosen lag structure.
As a rule of thumb, N > 30 + total number of parameters.{p_end}
{phang2}• No structural breaks in the sample period (or control for them
with exogenous dummies).{p_end}

{pstd}
{bf:Warnings:}

{phang2}• The bounds test has low power in small samples.
Consider finite-sample critical values ({cmd:ardlbounds}).{p_end}
{phang2}• If e(rho) >= 0, there is no error correction and the model
should be reconsidered.{p_end}
{phang2}• If diagnostic tests reject (serial correlation, heteroskedasticity),
inference may be unreliable. Consider adjusting the lag structure.{p_end}
{phang2}• One-step delta-method standard errors for LR coefficients may be
inaccurate in small samples. The two-step FM-OLS approach provides
more reliable LR inference.{p_end}


{marker references}{...}
{title:References}

{marker CGS2019}{...}
{phang}
Cho, J.S., Greenwood-Nimmo, M. and Shin, Y. (2019). Two-step estimation of
the nonlinear autoregressive distributed lag model. {it:Working papers}
{it:2019rwp-154}, Yonsei University, Yonsei Economics Research Institute.

{marker SYG2014}{...}
{phang}
Shin, Y., Yu, B. and Greenwood-Nimmo, M. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In:
Sickles, R., Horrace, W. (eds) {it:Festschrift in Honor of Peter Schmidt}.
Springer, New York, 281-314.

{marker PSS2001}{...}
{phang}
Pesaran, M.H., Shin, Y. and Smith, R.J. (2001). Bounds testing approaches
to the analysis of level relationships. {it:Journal of Applied Econometrics},
16(3), 289-326.

{marker PH1990}{...}
{phang}
Phillips, P.C.B. and Hansen, B.E. (1990). Statistical inference in
instrumental variables regression with I(1) processes. {it:Review of}
{it:Economic Studies}, 57(1), 99-125.

{marker PS1996}{...}
{phang}
Pesaran, M.H. and Shin, Y. (1996). Cointegration and speed of convergence
to equilibrium. {it:Journal of Econometrics}, 71(1-2), 117-143.

{marker KS2020}{...}
{phang}
Kripfganz, S. and Schneider, D.C. (2020). Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction
models. {it:Oxford Bulletin of Economics and Statistics}, 82(6), 1456-1481.

{phang}
Kripfganz, S. and Schneider, D.C. (2023). {cmd:ardl}: Estimating
autoregressive distributed lag and equilibrium correction models.
{it:Stata Journal}, 23(4), 983-1012.


{marker authors}{...}
{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com{break}
Independent Researcher

{pstd}
{bf:Please cite as:}{break}
Roudane, M. (2026). {cmd:twostep_nardl}: Two-step estimation of the nonlinear
ARDL model. Statistical Software Components, Boston College Department of
Economics.

{pstd}
{bf:Acknowledgments:}{break}
This package builds upon the {cmd:ardl} package by Kripfganz and Schneider
for bounds testing infrastructure, and implements the methodology of
Cho, Greenwood-Nimmo, and Shin (2019).


{marker alsosee}{...}
{title:Also see}

{pstd}
{help ardl:ardl} — ARDL estimation and bounds testing{break}
{help ardlbounds:ardlbounds} — Critical values for bounds tests{break}
{help tsset:tsset} — Declare time-series data{break}
{help regress:regress} — OLS regression{break}
{help nlcom:nlcom} — Nonlinear combinations
{p_end}
