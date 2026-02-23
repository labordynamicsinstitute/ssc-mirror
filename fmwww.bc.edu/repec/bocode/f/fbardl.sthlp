{smcl}
{* *! version 1.0.0  21feb2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
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
Restricted null on all level terms, residual resampling, recursive data
generation, bootstrap distributions for all three statistics.
{p_end}

{pstd}
{bf:type(fbardl_bvz):} Bertelli et al. (2022) conditional bootstrap.
Three separate nulls (F_ov, t_DV, F_ind), marginal VECM for independent
variables, joint resampling of ARDL and VECM residuals.
{p_end}

{pstd}
{ul:Degenerate Case Detection}
{p_end}

{pstd}
Following McNown et al. (2018), degenerate cases are detected when:
{p_end}

{phang2}
{bf:Degenerate #1:} F_ov and F_ind significant, t_DV not. Indicates y may be
I(0) rather than cointegrated with x variables.
{p_end}

{phang2}
{bf:Degenerate #2:} F_ov and t_DV significant, F_ind not. Indicates x variables
do not enter the error correction mechanism.
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
{opt case(#)} PSS case number (2-5). Default is 3 (unrestricted intercept,
no deterministic trend).
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
{phang3}Fourier Terms & Deterministics{p_end}
{phang2}Table 3: Cointegration Test Results (F_ov, t_DV, F_ind with CVs/p-values){p_end}
{phang2}Table 4: Diagnostic Tests (normality, serial correlation, heteroskedasticity, RESET, CUSUM){p_end}
{phang2}Table 5: Dynamic Multipliers (by horizon){p_end}
{phang2}Table 6: Half-Life & Persistence Profile (mean adj. lag, 90%/99% adjustment){p_end}
{phang2}Table 7: Fourier Terms Joint Significance F-test{p_end}
{phang2}Table 8: Long-Run Equilibrium Relationship{p_end}


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
{synopt:{cmd:e(type)}}model type{p_end}
{synopt:{cmd:e(ic)}}information criterion used{p_end}


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
{it:Oxford Bulletin of Economics and Statistics}, 82, 1456-1481.
{p_end}

{phang}
McNown, R., Sam, C.Y. & Goh, S.K. (2018). Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics}, 50(13), 1509-1521.
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
