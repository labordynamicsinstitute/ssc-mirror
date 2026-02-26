{smcl}
{* *! version 1.0.0  24feb2026}{...}
{viewerjumpto "Syntax" "mvardlurt##syntax"}{...}
{viewerjumpto "Description" "mvardlurt##description"}{...}
{viewerjumpto "Options" "mvardlurt##options"}{...}
{viewerjumpto "Output" "mvardlurt##output"}{...}
{viewerjumpto "Methodology" "mvardlurt##methodology"}{...}
{viewerjumpto "Decision framework" "mvardlurt##decision"}{...}
{viewerjumpto "Examples" "mvardlurt##examples"}{...}
{viewerjumpto "Stored results" "mvardlurt##stored"}{...}
{viewerjumpto "References" "mvardlurt##references"}{...}
{viewerjumpto "Author" "mvardlurt##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:mvardlurt} {hline 2}} Multivariate ARDL Unit Root Test with Bootstrap Critical Values{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mvardlurt}
{it:depvar}
{it:indepvar}
{ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt case(#)}}regression case; {bf:1} = no deterministics,
    {bf:3} = intercept (default), {bf:5} = intercept + trend{p_end}
{synopt:{opt maxlag(#)}}maximum ARDL lag order; default is {bf:10}{p_end}
{synopt:{opt ic(string)}}information criterion for lag selection;
    {bf:aic} (default) or {bf:bic}{p_end}
{synopt:{opt fixlag(# #)}}manually specify lag orders {it:p q} instead of auto-selection{p_end}

{syntab:Bootstrap}
{synopt:{opt reps(#)}}number of bootstrap replications; default is {bf:1000}{p_end}
{synopt:{opt seed(#)}}random number seed; default is {bf:12345}{p_end}
{synopt:{opt noboot}}suppress bootstrap; display observed statistics only{p_end}

{syntab:Display}
{synopt:{opt level(#)}}confidence level; default is {bf:95}{p_end}
{synopt:{opt notab:le}}suppress AIC/BIC selection table{p_end}
{synopt:{opt diag}}display diagnostic tests (Breusch-Godfrey, ARCH, RESET, White, Jarque-Bera){p_end}
{synopt:{opt nograph}}suppress graphs{p_end}
{synoptline}

{pstd}
Data must be {cmd:tsset} before using {cmd:mvardlurt}. Panel data is not supported.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mvardlurt} implements the {bf:multivariate ARDL unit root test} proposed by
Sam, McNown, Goh, and Goh (2024). This test augments the standard ADF regression
with the lagged level of a covariate (independent variable) to improve power,
especially when cointegration exists between the dependent and independent variables.

{pstd}
The command produces {bf:four output tables}:

{p 8 12 2}
{bf:Table 1 -- ARDL Unit Root Test}: main results including model specification,
test statistics, and sample information (matches the EViews {it:table_result} format).{p_end}

{p 8 12 2}
{bf:Table 2 -- Bootstrap Critical Values}: bootstrap-based critical values at
10%, 5%, 2.5%, and 1% significance levels for both t and F tests.{p_end}

{p 8 12 2}
{bf:Table 3 -- Coefficient Summary}: estimated coefficients for pi (unit root) and
delta (cointegration), their standard errors, and the implied long-run multiplier.{p_end}

{p 8 12 2}
{bf:Table 4 -- Decision and Inference}: comprehensive decision table with hypothesis test
results, the four-case framework from Sam et al. (2024), and a detailed conclusion.{p_end}

{pstd}
The test provides two test statistics:

{p 8 12 2}
{bf:t-statistic}: tests H0: pi = 0 (the dependent variable has a unit root),
computed as the t-ratio on the lagged level of the dependent variable.
{bf:Reject if t < t-critical} (left-tail test).{p_end}

{p 8 12 2}
{bf:F-statistic}: tests H0: delta = 0 (no cointegrating relationship via the
independent variable), computed as the Wald statistic on the lagged level of
the independent variable.
{bf:Reject if F > F-critical} (right-tail test).{p_end}

{pstd}
Because the null distributions are non-standard and nuisance-parameter dependent,
{cmd:mvardlurt} generates {bf:bootstrap critical values} using the parametric
bootstrap procedure of Sam et al. (2024). The bootstrap imposes the joint null
hypothesis (pi = 0, delta = 0), resamples residuals with replacement, and
regenerates the data recursively to simulate the null distribution.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt case(#)} specifies the deterministic terms in the regression.
This directly corresponds to the EViews {it:%regtype} variable:

{p 12 16 2}
{bf:case(1)}: no intercept, no trend (EViews: {bf:%regtype = "n"}).
The regression is estimated with {cmd:noconstant}.{p_end}

{p 12 16 2}
{bf:case(3)}: intercept only (default; EViews: {bf:%regtype = "i"}).
This is the most common specification.{p_end}

{p 12 16 2}
{bf:case(5)}: intercept and trend (EViews: {bf:%regtype = "t"}).
Includes a deterministic linear trend.{p_end}

{phang}
{opt maxlag(#)} specifies the maximum lag order to consider during AIC/BIC-based
lag selection. Default is 10. The optimal ARDL(p, q) model is selected via
exhaustive grid search over p = 0, ..., {it:maxlag} and q = 0, ..., {it:maxlag}.
The number of models evaluated is ({it:maxlag}+1)^2.

{phang}
{opt ic(string)} specifies the information criterion for lag selection.
{bf:aic} (Akaike, default) or {bf:bic} (Bayesian/Schwarz).
Both criteria are computed from the standard formula:
AIC = -2*LL + 2*k; BIC = -2*LL + k*ln(n).

{phang}
{opt fixlag(# #)} manually specifies the lag orders {it:p} (for dy) and {it:q}
(for dx), bypassing automatic selection. For example, {cmd:fixlag(2 3)}
specifies ARDL(2, 3). This is useful when the researcher has prior knowledge
of the appropriate lag structure.

{dlgtab:Bootstrap}

{phang}
{opt reps(#)} specifies the number of bootstrap replications. The default is 1000.
Minimum is 100. Recommended values for published work are:

{p 12 16 2}
{bf:1000}: adequate for exploratory analysis{p_end}
{p 12 16 2}
{bf:2000}: good for most applications{p_end}
{p 12 16 2}
{bf:5000}: recommended for publication{p_end}
{p 12 16 2}
{bf:10000}: best precision (matches the Sam et al. EViews default){p_end}

{phang}
{opt seed(#)} specifies the random number seed for reproducibility. Default is 12345,
following the EViews program convention.

{phang}
{opt noboot} suppresses the bootstrap. Only the observed t-statistic and
F-statistic are displayed in Table 1, but no critical values (Table 2)
or decision (Table 4) are available.

{dlgtab:Display}

{phang}
{opt notable} suppresses the AIC/BIC lag selection table. The optimal model
is still selected and used, but the full grid is not displayed.

{phang}
{opt diag} displays diagnostic tests after the main results. Tests include:
Breusch-Godfrey serial correlation (lag 1), ARCH LM (lag 1),
Ramsey RESET, White heteroskedasticity, and Jarque-Bera normality.
By default, diagnostics are not shown to keep output focused on the
unit root test results.

{phang}
{opt nograph} suppresses all graphical output. By default, {cmd:mvardlurt}
produces diagnostic plots.


{marker output}{...}
{title:Output tables}

{pstd}
{bf:Table 1: ARDL Unit Root Test}

{pstd}
Displays the main model information and test statistics in a format equivalent
to the EViews {it:table_result} object. Includes dependent/independent variables,
sample period, optimal ARDL(p,q) model, AIC, R-squared, and the observed
t-statistic (tests unit root) and F-statistic (tests no cointegration).

{pstd}
{bf:Table 2: Bootstrap Critical Values}

{pstd}
Shows bootstrap critical values at the 10%, 5%, 2.5%, and 1% significance
levels for both the t-test and F-test. These are the quantiles of the
bootstrap distribution generated under the joint null hypothesis.
The t-critical values are from the lower tail (reject if t < critical),
and the F-critical values are from the upper tail (reject if F > critical).

{pstd}
{bf:Table 3: ARDL Coefficient Summary}

{pstd}
Reports the key estimated coefficients from the ARDL ECM regression:

{p 8 12 2}
{bf:pi} (unit root coefficient): the coefficient on L.{it:depvar}. A significantly
negative pi implies error correction / stationarity.{p_end}

{p 8 12 2}
{bf:delta} (cointegration coefficient): the coefficient on L.{it:indepvar}. A
significant delta implies that {it:indepvar} enters the long-run equilibrium.{p_end}

{p 8 12 2}
{bf:Long-run multiplier} (delta/pi): the implied long-run effect of a unit
change in {it:indepvar} on {it:depvar} in the cointegrating relationship.{p_end}

{pstd}
{bf:Table 4: Decision and Inference}

{pstd}
Provides a comprehensive decision summary in three parts:

{p 8 12 2}
{bf:Part A -- Hypothesis Tests}: Shows whether each test rejects or fails to
reject the null, with significance stars and level.{p_end}

{p 8 12 2}
{bf:Part B -- Four-Case Framework}: Displays all four possible outcome combinations
from Sam et al. (2024) with an arrow ({bf:=>}) marking the applicable case.{p_end}

{p 8 12 2}
{bf:Part C -- Conclusion}: Provides the detailed economic interpretation of the
applicable case, including the integration order and cointegration status.{p_end}


{marker decision}{...}
{title:Four-case decision framework}

{pstd}
Following Sam, McNown, Goh, and Goh (2024), the joint use of both t-test and
F-test produces four possible cases:

{col 5}{bf:Case}{col 14}{bf:t-test}{col 26}{bf:F-test}{col 38}{bf:Conclusion}
{col 5}{hline 68}
{col 5}I{col 14}Reject{col 26}Reject{col 38}{bf:Cointegration}: ECM is valid
{col 5}II{col 14}Reject{col 26}Accept{col 38}{bf:Degenerate 1}: y may be I(0)
{col 5}III{col 14}Accept{col 26}Reject{col 38}{bf:Degenerate 2}: spurious
{col 5}IV{col 14}Accept{col 26}Accept{col 38}{bf:No cointegration}: y is I(1)
{col 5}{hline 68}

{pstd}
{bf:Case I -- Cointegration}: Both tests reject their nulls. The dependent
variable is stationary (or error-correcting), and the independent variable
enters the long-run equation. This provides evidence of a cointegrating
relationship, and the error correction model is valid.

{pstd}
{bf:Case II -- Degenerate case 1}: Only the t-test rejects. The dependent variable
appears to be stationary or I(0), but the independent variable does not contribute
to the long-run equilibrium. The independent variable is not a cointegrator.

{pstd}
{bf:Case III -- Degenerate case 2}: Only the F-test rejects. The independent
variable appears significant, but the dependent variable has a unit root. This
is a spurious result -- the unit root in the dependent variable invalidates
the long-run relationship. See Sam et al. (2024) for details.

{pstd}
{bf:Case IV -- No cointegration}: Both tests fail to reject their nulls. The
dependent variable has a unit root and there is no cointegrating relationship
with the independent variable.


{marker methodology}{...}
{title:Methodology}

{pstd}
The multivariate ARDL unit root test regression (ECM form) is:

{p 8 12 2}
{it:Case 1 (no deterministics):}{p_end}
{p 10 14 2}
Dy_t = pi * y_{t-1} + delta * x_{t-1} + sum(phi_j * Dy_{t-j}) + sum(psi_k * Dx_{t-k}) + e_t{p_end}

{p 8 12 2}
{it:Case 3 (intercept):} same as above + c{p_end}

{p 8 12 2}
{it:Case 5 (trend):} same as above + c + t{p_end}

{pstd}
{bf:Automatic lag selection:}

{pstd}
When {opt fixlag()} is not specified, {cmd:mvardlurt} performs an exhaustive grid
search over all ARDL(p,q) specifications with p = 0,...,maxlag and q = 0,...,maxlag.
The optimal model minimizes the selected information criterion (AIC or BIC).
This mirrors the EViews algorithm exactly.

{pstd}
{bf:Test Statistics:}

{p 8 12 2}
t-statistic: t-ratio on y_{t-1}; reject H0 (unit root) if t < t-critical (left-tail){p_end}

{p 8 12 2}
F-statistic: Wald test on x_{t-1}; reject H0 (no cointegration) if F > F-critical (right-tail){p_end}

{pstd}
{bf:Bootstrap Procedure:}

{p 8 12 2}
1. Estimate restricted model under H0 (setting pi = 0 and delta = 0){p_end}
{p 8 12 2}
2. Extract residuals and recenter to mean zero{p_end}
{p 8 12 2}
3. Resample residuals with replacement{p_end}
{p 8 12 2}
4. Generate bootstrap dependent variable recursively using estimated DGP{p_end}
{p 8 12 2}
5. Re-estimate the unrestricted model on bootstrap data{p_end}
{p 8 12 2}
6. Store bootstrap t and F statistics{p_end}
{p 8 12 2}
7. Repeat steps 3-6 for {it:reps} replications{p_end}
{p 8 12 2}
8. Compute critical values as quantiles of bootstrap distributions{p_end}

{pstd}
The bootstrap ensures correct size and excellent power regardless of whether
the series is nonstationary, stationary, or cointegrated.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic test with automatic lag selection (intercept case)}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset}{p_end}
{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(3) maxlag(4) reps(1000)}{p_end}

{pstd}
This runs the multivariate ARDL unit root test on {it:ln_inv} using {it:ln_inc}
as the covariate, with intercept (Case 3), maximum 4 lags, and 1000 bootstrap
replications. The output includes Tables 1-4 with test statistics, bootstrap
critical values, coefficient summary, and the decision framework.

{pstd}
{bf:Example 2: Trend case with BIC selection and more replications}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(5) maxlag(6) ic(bic) reps(5000)}{p_end}

{pstd}
Includes a deterministic trend (Case 5), uses BIC for lag selection with maximum
6 lags, and increases bootstrap replications to 5000 for publication quality.

{pstd}
{bf:Example 3: No deterministic terms (Case 1)}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(1) maxlag(4) reps(1000)}{p_end}

{pstd}
{bf:Example 4: Manual lag specification}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, fixlag(2 1) case(3) reps(1000) nograph}{p_end}

{pstd}
Manually sets ARDL(2,1) and suppresses graphs. Useful when the researcher
knows the appropriate lag structure.

{pstd}
{bf:Example 5: Quick preliminary check without bootstrap}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(3) maxlag(4) noboot nograph}{p_end}

{pstd}
Shows Tables 1 and 3 (test statistics and coefficients) without bootstrap
critical values. Useful for a quick preliminary analysis.

{pstd}
{bf:Example 6: Full analysis with diagnostics}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(3) maxlag(4) reps(2000) diag}{p_end}

{pstd}
Includes diagnostic tests (Breusch-Godfrey, ARCH, RESET, White, Jarque-Bera)
in addition to the standard output tables.

{pstd}
{bf:Example 7: Accessing stored results}

{phang2}{cmd:. mvardlurt ln_inv ln_inc, case(3) maxlag(4) reps(1000) nograph}{p_end}
{phang2}{cmd:. display "t-stat = " e(tstat)}{p_end}
{phang2}{cmd:. display "5% t-crit = " e(t_cv05)}{p_end}
{phang2}{cmd:. display "F-stat = " e(fstat)}{p_end}
{phang2}{cmd:. display "5% F-crit = " e(f_cv05)}{p_end}
{phang2}{cmd:. display "Long-run multiplier = " e(lr_mult)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mvardlurt} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(tstat)}}observed t-statistic on L.{it:depvar}{p_end}
{synopt:{cmd:e(fstat)}}observed F-statistic on L.{it:indepvar}{p_end}
{synopt:{cmd:e(fstat_p)}}asymptotic p-value for F-test{p_end}
{synopt:{cmd:e(pi_coef)}}coefficient on L.{it:depvar} (pi){p_end}
{synopt:{cmd:e(pi_se)}}standard error on L.{it:depvar}{p_end}
{synopt:{cmd:e(delta_coef)}}coefficient on L.{it:indepvar} (delta){p_end}
{synopt:{cmd:e(delta_se)}}standard error on L.{it:indepvar}{p_end}
{synopt:{cmd:e(lr_mult)}}long-run multiplier (delta/pi){p_end}
{synopt:{cmd:e(opt_p)}}optimal lag p for Dy{p_end}
{synopt:{cmd:e(opt_q)}}optimal lag q for Dx{p_end}
{synopt:{cmd:e(case)}}regression case (1, 3, or 5){p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(T)}}sample size{p_end}
{synopt:{cmd:e(aic)}}Akaike information criterion{p_end}
{synopt:{cmd:e(bic)}}Bayesian information criterion{p_end}
{synopt:{cmd:e(t_cv10)}}bootstrap t-critical value at 10%{p_end}
{synopt:{cmd:e(t_cv05)}}bootstrap t-critical value at 5%{p_end}
{synopt:{cmd:e(t_cv025)}}bootstrap t-critical value at 2.5%{p_end}
{synopt:{cmd:e(t_cv01)}}bootstrap t-critical value at 1%{p_end}
{synopt:{cmd:e(f_cv10)}}bootstrap F-critical value at 10%{p_end}
{synopt:{cmd:e(f_cv05)}}bootstrap F-critical value at 5%{p_end}
{synopt:{cmd:e(f_cv025)}}bootstrap F-critical value at 2.5%{p_end}
{synopt:{cmd:e(f_cv01)}}bootstrap F-critical value at 1%{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mvardlurt}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvar)}}independent variable name{p_end}
{synopt:{cmd:e(casename)}}case description (e.g. "Intercept Only"){p_end}
{synopt:{cmd:e(ic)}}information criterion used (aic or bic){p_end}
{synopt:{cmd:e(title)}}model title{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector from the optimal ARDL regression{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(aic_table)}}(maxlag+1) x (maxlag+1) matrix of IC values (if auto-selection){p_end}


{marker references}{...}
{title:References}

{phang}
Sam, C. Y., McNown, R., Goh, S. K., and Goh, K. L. (2024). A multivariate
autoregressive distributed lag unit root test. {it:Studies in Economics and}
{it:Econometrics}, 1-17.

{phang}
McNown, R., Sam, C. Y., and Goh, S. K. (2018). Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics}, 50, 1509-1521.

{phang}
Pesaran, M. H., Shin, Y., and Smith, R. J. (2001). Bounds testing approaches
to the analysis of level relationships. {it:Journal of Applied Econometrics},
16, 289-326.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Please cite:{break}
Sam, C. Y., McNown, R., Goh, S. K., and Goh, K. L. (2024). A multivariate
autoregressive distributed lag unit root test. {it:Studies in Economics and}
{it:Econometrics}, 1-17.
{p_end}
