{smcl}
{* *! version 1.0.0  24feb2026}{...}
{viewerjumpto "Syntax" "mtnardl##syntax"}{...}
{viewerjumpto "Description" "mtnardl##description"}{...}
{viewerjumpto "Options" "mtnardl##options"}{...}
{viewerjumpto "Output tables" "mtnardl##output"}{...}
{viewerjumpto "Graphs" "mtnardl##graphs"}{...}
{viewerjumpto "Examples" "mtnardl##examples"}{...}
{viewerjumpto "Stored results" "mtnardl##results"}{...}
{viewerjumpto "References" "mtnardl##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:mtnardl} {hline 2}}Bootstrap Multiple Threshold Nonlinear ARDL{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mtnardl} {depvar} {indepvars} {ifin}{cmd:,} {opt decompose(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt decompose(varlist)}}variables to decompose into quantile-based partial sums{p_end}

{syntab:Decomposition}
{synopt:{opt partition(string)}}partition type: {bf:quartile} (4), {bf:quintile} (5, default),
    {bf:decile} (10), {bf:percentile} (20), or {bf:custom}{p_end}
{synopt:{opt cutpoints(numlist)}}custom quantile cutpoints (required when partition=custom){p_end}

{syntab:Lag Selection}
{synopt:{opt maxlag(#)}}maximum lag order for selection; default is {bf:4}{p_end}
{synopt:{opt ic(string)}}information criterion: {bf:aic} (default) or {bf:bic}{p_end}

{syntab:Model}
{synopt:{opt case(#)}}PSS case for deterministic terms (2-5); default is {bf:3}{p_end}
{synopt:{opt level(#)}}confidence level; default is {bf:95}{p_end}
{synopt:{opt horizon(#)}}dynamic multiplier horizon; default is {bf:20}{p_end}

{syntab:Estimation Type}
{synopt:{opt type(string)}}estimation method: {bf:mtnardl} (default), {bf:mtnardl_mcnown},
    or {bf:mtnardl_bvz}{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default is {bf:999}{p_end}

{syntab:Display}
{synopt:{opt notable}}suppress regression coefficient table{p_end}
{synopt:{opt nodiag}}suppress diagnostic tests{p_end}
{synopt:{opt nodynamult}}suppress dynamic multiplier output{p_end}
{synopt:{opt noadvanced}}suppress advanced analysis{p_end}
{synopt:{opt nograph}}suppress all graphs{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mtnardl} implements the Multiple Threshold Nonlinear Autoregressive
Distributed Lag (MTNARDL) model proposed by {help mtnardl##Pal2016:Pal and Mitra (2016)}.

{pstd}
Unlike the standard Nonlinear ARDL (NARDL) which decomposes changes into
positive and negative components (binary split), the MTNARDL decomposes changes
in independent variables into {it:quantile-based regimes}. This allows testing
whether the {it:magnitude} of price changes matters for transmission asymmetry,
not just the direction.

{pstd}
The command provides a comprehensive analysis pipeline:

{phang2}1. {bf:Quantile decomposition} of independent variables into partial sums
    (quartiles, quintiles, deciles, percentiles, or custom cutpoints){p_end}
{phang2}2. {bf:Automatic lag selection} via AIC/BIC with individual lag orders per
    regime variable{p_end}
{phang2}3. {bf:Cointegration testing} with PSS/KS critical values or bootstrap
    methods (McNown et al. 2018; Bertelli et al. 2022){p_end}
{phang2}4. {bf:Error correction representation} with long-run coefficients per
    regime (delta method standard errors){p_end}
{phang2}5. {bf:Dynamic multipliers} per quantile regime with cumulative
    multiplier graphs{p_end}
{phang2}6. {bf:Comprehensive diagnostic tests} (normality, serial correlation,
    heteroskedasticity, RESET, CUSUM){p_end}
{phang2}7. {bf:Wald tests} for long-run and short-run symmetry across regimes{p_end}
{phang2}8. {bf:Asymmetric analysis} with ratios, pairwise comparisons, and
    publication-quality graphs{p_end}

{pstd}
{bf:Methodology:} The MTNARDL decomposes changes in each independent variable
{it:x_t} into {it:Q} quantile-based partial sums:

{pstd}
{it:x_t = x_0 + sum_{q=1}^{Q} x_t^{(q)}}

{pstd}
where {it:x_t^{(q)} = sum_{j=1}^{t} Delta_x_j * I(c_{q-1} < Delta_x_j <= c_q)} and
{it:c_q} are the quantile cutpoints. The ARDL model is then:

{pstd}
{it:Delta_y_t = alpha*y_{t-1} + sum_{q=1}^{Q} theta_q * x_{t-1}^{(q)} + SR terms + u_t}

{pstd}
Long-run multipliers per regime are {it:beta_q = -theta_q / alpha}.

{marker options}{...}
{title:Options}

{dlgtab:Decomposition}

{phang}
{opt partition(string)} specifies how changes in the decomposed variables are
binned. {bf:quartile} creates 4 bins at the 25th, 50th, 75th percentiles;
{bf:quintile} (default) creates 5 bins; {bf:decile} creates 10 bins;
{bf:percentile} creates 20 bins; {bf:custom} uses the cutpoints specified in
{opt cutpoints()}.

{phang}
{opt cutpoints(numlist)} specifies custom threshold cutpoints for the
decomposition when {opt partition(custom)} is used. For example,
{cmd:cutpoints(-0.03 -0.01 0.01 0.03)} creates 5 regimes: large decrease,
small decrease, neutral, small increase, large increase.

{dlgtab:Lag Selection}

{phang}
{opt maxlag(#)} sets the maximum lag order to consider during the automatic lag
selection procedure. For each regime variable, {cmd:mtnardl} evaluates all
possible lag combinations from 0 to {it:maxlag} and selects the combination
that minimizes the chosen information criterion.

{phang}
{opt ic(string)} specifies the information criterion for lag selection.
{bf:aic} (default) tends to select more parsimonious models in small samples.
{bf:bic} penalizes additional parameters more heavily.

{dlgtab:Model}

{phang}
{opt case(#)} specifies the deterministic terms in the PSS framework:
{bf:2} = restricted intercept, no trend;
{bf:3} = unrestricted intercept, no trend (default);
{bf:4} = unrestricted intercept, restricted trend;
{bf:5} = unrestricted intercept, unrestricted trend.

{phang}
{opt horizon(#)} specifies the number of periods for dynamic multiplier
computation. Default is {bf:20}.

{dlgtab:Estimation Type}

{phang}
{opt type(mtnardl)} (default) uses PSS bounds test with
{help mtnardl##KS2020:Kripfganz and Schneider (2020)} critical values
obtained via the {cmd:ardlbounds} package.

{phang}
{opt type(mtnardl_mcnown)} uses the
{help mtnardl##McNown2018:McNown, Sam and Goh (2018)} unconditional bootstrap
for cointegration testing. This method bootstraps both the dependent variable
and the decomposed independent variables under the null of no cointegration.

{phang}
{opt type(mtnardl_bvz)} uses the
{help mtnardl##BVZ2022:Bertelli, Vacca and Zoia (2022)} conditional bootstrap.
This method uses restricted residuals from three separate null hypotheses
(F_overall, t_dependent, F_independent) for more powerful testing.

{phang}
{opt reps(#)} specifies the number of bootstrap replications. Default is
{bf:999}. Higher values (e.g., 1999) give more stable results at the cost
of computation time.

{marker output}{...}
{title:Output Tables}

{pstd}
{cmd:mtnardl} produces the following tables:

{dlgtab:Table 1: Model Selection Summary}

{pstd}
Reports the partition type, number of regimes, optimal ARDL specification
(p, q1, q2, ..., qQ), observations, R-squared, AIC/BIC, F-statistic, RMSE,
and number of models evaluated.

{dlgtab:Table 2: EC Representation}

{pstd}
Displays the Error Correction representation with:

{phang2}{bf:ADJ} — Speed of adjustment coefficient (ECM term, L.{it:depvar}){p_end}
{phang2}{bf:LR} — Long-run coefficients per regime with delta-method standard
    errors, z-statistics, p-values, and 95% confidence intervals{p_end}
{phang2}{bf:SR} — Short-run (first-difference) coefficients{p_end}
{phang2}{bf:Deterministics} — Constant and trend terms{p_end}

{dlgtab:Table 3: Cointegration Tests}

{pstd}
Reports cointegration test results using either:

{phang2}{bf:PSS Bounds Test} — F_overall, t_dependent, F_independent with
    10%, 5%, 1% critical values from {cmd:ardlbounds}{p_end}
{phang2}{bf:Bootstrap Tests} — Same three statistics with bootstrap
    p-values and bootstrap critical values (1%, 5%, 10%){p_end}

{pstd}
Cointegration is confirmed when all three tests reject their respective
null hypotheses.

{dlgtab:Table 4: Diagnostic Tests}

{pstd}
Comprehensive residual diagnostics:

{phang2}{bf:A. Normality:} Jarque-Bera, Shapiro-Wilk, Shapiro-Francia{p_end}
{phang2}{bf:B. Serial Correlation:} Breusch-Godfrey LM(1) through LM(4),
    Durbin-Watson{p_end}
{phang2}{bf:C. Heteroskedasticity:} ARCH LM(1), ARCH LM(4), White's test{p_end}
{phang2}{bf:D. Functional Form:} Ramsey RESET{p_end}
{phang2}{bf:E. Stability:} CUSUM and CUSUM-SQ{p_end}

{dlgtab:Advanced Analysis}

{pstd}
Additional post-estimation analysis (suppress with {opt noadvanced}):

{phang2}{bf:Speed of Adjustment:} Half-life, 50%/90%/99% adjustment times{p_end}
{phang2}{bf:Persistence Profile:} Pesaran and Shin (1996) profile showing
    convergence speed to equilibrium{p_end}
{phang2}{bf:LR Equilibrium:} Long-run coefficients per regime with standard
    errors{p_end}
{phang2}{bf:Wald Tests for Asymmetry:}{p_end}
{phang3}D1. Joint LR symmetry test (H0: all LR multipliers equal) via
    Wald chi-squared{p_end}
{phang3}D2. Joint SR symmetry test and pairwise extreme-regime test{p_end}

{phang2}{bf:Asymmetric Analysis:}{p_end}
{phang3}E1. Asymmetric ratios — max/min and adjacent-regime LR ratios with
    interpretation (Strong/Moderate/Mild/Near symmetric){p_end}
{phang3}E2. Pairwise LR differences — all regime-pair comparisons with
    delta-method z-tests{p_end}
{phang3}E3. LR coefficient bar chart — visual plot by regime{p_end}
{phang3}E4. Regime summary — compact table with ratios, magnitudes, and
    signs{p_end}

{marker graphs}{...}
{title:Graphs}

{pstd}
{cmd:mtnardl} produces the following publication-quality graphs (suppress
with {opt nograph}):

{phang2}{bf:mtnardl_decomp_}{it:var}{bf:.png} — Stacked partial-sum
    decomposition showing how each regime accumulates over time{p_end}
{phang2}{bf:mtnardl_cummult_}{it:var}{bf:.png} — Cumulative dynamic
    multipliers per regime, showing adjustment paths{p_end}
{phang2}{bf:mtnardl_asym_}{it:var}{bf:.png} — Asymmetry graph showing
    differences between regime multiplier paths{p_end}
{phang2}{bf:mtnardl_persistence.png} — Persistence profile showing
    convergence to long-run equilibrium{p_end}
{phang2}{bf:mtnardl_lr_asym_}{it:var}{bf:.png} — Bar chart of long-run
    coefficients by regime (blue = positive, red = negative){p_end}

{marker examples}{...}
{title:Examples}

{pstd}Example 1: Basic MTNARDL with quartile decomposition and PSS bounds test{p_end}
{phang2}{cmd:. mtnardl lpetrol lcrude, decompose(lcrude) partition(quartile) maxlag(4) case(3)}{p_end}

{pstd}Example 2: Quartile decomposition with McNown et al. bootstrap{p_end}
{phang2}{cmd:. mtnardl lpetrol lcrude, decompose(lcrude) partition(quartile) maxlag(4) case(3) type(mtnardl_mcnown) reps(299)}{p_end}

{pstd}Example 3: Decile decomposition (10 regimes){p_end}
{phang2}{cmd:. mtnardl lpetrol lcrude, decompose(lcrude) partition(decile) maxlag(4) case(3)}{p_end}

{pstd}Example 4: Custom cutpoints defining 5 regimes{p_end}
{phang2}{cmd:. mtnardl lpetrol lcrude, decompose(lcrude) partition(custom) cutpoints(-0.03 -0.01 0.01 0.03) maxlag(4) case(3)}{p_end}

{pstd}Example 5: Bertelli et al. conditional bootstrap{p_end}
{phang2}{cmd:. mtnardl latf lcrude, decompose(lcrude) partition(quintile) maxlag(4) case(3) type(mtnardl_bvz) reps(299)}{p_end}

{pstd}Example 6: Suppress graphs and advanced analysis{p_end}
{phang2}{cmd:. mtnardl lpetrol lcrude, decompose(lcrude) partition(quartile) nograph noadvanced}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mtnardl} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(best_p)}}optimal lag order for dependent variable{p_end}
{synopt:{cmd:e(nq)}}number of quantile regimes{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(aic)}}Akaike information criterion{p_end}
{synopt:{cmd:e(bic)}}Bayesian information criterion{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(F)}}model F-statistic{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(Fov)}}F-overall cointegration test statistic{p_end}
{synopt:{cmd:e(t_dep)}}t-dependent cointegration test statistic{p_end}
{synopt:{cmd:e(Find)}}F-independent cointegration test statistic{p_end}
{synopt:{cmd:e(ecm_coef)}}ECM (speed of adjustment) coefficient{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mtnardl}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(decompose)}}decomposed variable(s){p_end}
{synopt:{cmd:e(partition)}}partition type used{p_end}
{synopt:{cmd:e(type)}}estimation type{p_end}
{synopt:{cmd:e(ardl_spec)}}ARDL specification string{p_end}
{synopt:{cmd:e(ic)}}information criterion used{p_end}
{synopt:{cmd:e(case)}}PSS case number{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}

{marker references}{...}
{title:References}

{marker Pal2016}{...}
{phang}
Pal, D. and Mitra, S.K. (2016). Asymmetric oil product pricing in India:
Evidence from a multiple threshold nonlinear ARDL model.
{it:Economic Modelling}, 59, 314-328.

{marker PSS2001}{...}
{phang}
Pesaran, M.H., Shin, Y. and Smith, R.J. (2001). Bounds testing approaches to
the analysis of level relationships. {it:Journal of Applied Econometrics},
16(3), 289-326.

{marker SYG2014}{...}
{phang}
Shin, Y., Yu, B. and Greenwood-Nimmo, M. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In:
Sickles, R., Horrace, W. (eds) {it:Festschrift in Honor of Peter Schmidt}.
Springer, New York, NY.

{marker McNown2018}{...}
{phang}
McNown, R., Sam, C.Y. and Goh, S.K. (2018). Bootstrapping the
autoregressive distributed lag test for cointegration.
{it:Applied Economics}, 50(13), 1509-1521.

{marker BVZ2022}{...}
{phang}
Bertelli, S., Vacca, G. and Zoia, M. (2022). Bootstrap cointegration tests
in ARDL models. {it:Economic Modelling}, 116, 105985.

{marker KS2020}{...}
{phang}
Kripfganz, S. and Schneider, D.C. (2020). Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics}, 82(6), 1456-1481.

{marker PS1996}{...}
{phang}
Pesaran, M.H. and Shin, Y. (1996). Cointegration and speed of convergence
to equilibrium. {it:Journal of Econometrics}, 71(1-2), 117-143.

{title:Author}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com{break}
Independent Researcher
{p_end}
