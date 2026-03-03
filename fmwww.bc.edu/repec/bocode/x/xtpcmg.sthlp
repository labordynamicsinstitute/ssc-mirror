{smcl}
{* *! version 1.0.0 01mar2026}{...}
{vieweralsosee "xtpmg" "help xtpmg"}{...}
{vieweralsosee "pnardl" "help pnardl"}{...}
{viewerjumpto "Syntax" "xtpcmg##syntax"}{...}
{viewerjumpto "Description" "xtpcmg##description"}{...}
{viewerjumpto "Options" "xtpcmg##options"}{...}
{viewerjumpto "Advanced Output" "xtpcmg##advanced"}{...}
{viewerjumpto "Diagnostic Graphs" "xtpcmg##graphs"}{...}
{viewerjumpto "Stored Results" "xtpcmg##stored"}{...}
{viewerjumpto "Examples" "xtpcmg##examples"}{...}
{viewerjumpto "References" "xtpcmg##references"}{...}
{viewerjumpto "Author" "xtpcmg##author"}{...}
{title:Title}

{phang}
{bf:xtpcmg} {hline 2} Panel Cointegrating Polynomial Regressions: Group-Mean & Pooled FM-OLS (v1.0.0)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpcmg} {it:depvar} {it:regressors} {ifin} {cmd:,} {opt m:odel(string)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt m:odel(string)}}estimation method: {bf:mg} (Group-Mean FM-OLS) or {bf:pmg} (Pooled FM-OLS); required{p_end}
{synopt :{opt q(#)}}polynomial degree: {bf:2} (quadratic) or {bf:3} (cubic); default is {bf:2}{p_end}
{synopt :{opt pol:y(varname)}}variable receiving the polynomial expansion; default is the first regressor{p_end}

{syntab:Deterministic Components}
{synopt :{opt trend(#)}}{it:(mg only)} 1 = individual intercepts; 2 = individual intercepts + linear trends; default is {bf:1}{p_end}
{synopt :{opt effects(string)}}{it:(pmg only)} {bf:oneway} = individual FE; {bf:twoway} = individual + time FE; default is {bf:oneway}{p_end}

{syntab:HAC Estimation}
{synopt :{opt kern:el(string)}}kernel: {bf:ba} (Bartlett, default), {bf:tr} (Truncated), {bf:pa} (Parzen), {bf:bo} (Bohman), {bf:da} (Daniell), {bf:qs} (Quadratic Spectral){p_end}
{synopt :{opt bw(string)}}bandwidth: {bf:And91} (Andrews 1991, default), or a positive integer{p_end}

{syntab:Advanced}
{synopt :{opt corrrob}}{it:(mg only)} cross-sectional dependence robust VCV matrix{p_end}
{synopt :{opt graph}}produce comprehensive diagnostic plots (7 graphs for mg, 4 for pmg){p_end}
{synopt :{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}You must {cmd:xtset} your data before using {cmd:xtpcmg}; see {help xtset}. The panel must be strongly balanced.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpcmg} estimates Fully Modified OLS (FM-OLS) for Panel Cointegrating Polynomial Regressions (CPRs).
Polynomial cointegration models arise when a dependent variable is linked not just to an integrated
process but also to its higher-order powers. The leading application is the Environmental Kuznets
Curve (EKC), where CO2 emissions follow a quadratic or cubic function of GDP.
Standard panel cointegration estimators are inconsistent for these models because the polynomial
powers are perfectly correlated with the level of the integrated process.
{cmd:xtpcmg} applies the specialised FM-OLS corrections developed in the recent econometrics
literature.
{p_end}

{pstd}
{bf:Multiple regressors.} The user selects which variable receives the polynomial expansion via
{opt poly(varname)}. All other regressors enter linearly as controls. If {opt poly()} is omitted,
the first regressor is expanded.
{p_end}

{pstd}
{cmd:xtpcmg} implements two estimators:
{p_end}

{pstd}
{bf:1. Group-Mean FM-OLS} ({cmd:model(mg)}){break}
Based on Wagner and Reichold (2023, {it:Econometric Reviews}).
Each cross-section unit is individually corrected using HAC long-run variance estimation.
The group-mean estimator averages the individual FM-OLS coefficients, yielding a
consistent and asymptotically normal estimator under cross-sectional independence.
When cross-sectional dependence is suspected, the {opt corrrob} option provides a
robust VCV using the full 2N x 2N long-run covariance matrix.
{p_end}

{pstd}
{bf:2. Pooled FM-OLS} ({cmd:model(pmg)}){break}
Based on de Jong and Wagner (2022, {it:Econometrics and Statistics}).
The pooled estimator stacks the panel and uses averaged long-run variances,
scaling by the exact deterministic asymptotic limits (M and Q matrices).
Individual or two-way fixed effects are removed before estimation.
{p_end}

{pstd}
{bf:Automatic advanced analysis.} After estimation, {cmd:xtpcmg} automatically displays:
{p_end}

{p 8 12 2}
{bf:(i)} Individual FM-OLS coefficient table (mg only), showing each panel's estimates.{break}
{bf:(ii)} Coefficient heterogeneity analysis with descriptive statistics (mean, median, SD, IQR,
skewness, kurtosis) and percentile distribution (min, P5, P25, P75, P95, max).{break}
{bf:(iii)} Swamy (1970) test for slope homogeneity across panels.{break}
{bf:(iv)} Between-within variance decomposition to distinguish systematic heterogeneity from
estimation noise.{break}
{bf:(v)} Turning point analysis with delta-method confidence intervals (quadratic) or two
critical points (cubic).
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(string)} selects the estimation method. {cmd:model(mg)} for Group-Mean FM-OLS
(Wagner and Reichold 2023) or {cmd:model(pmg)} for Pooled FM-OLS (de Jong and Wagner 2022).
This option is required.
{p_end}

{phang}
{opt q(#)} sets the polynomial degree of the cointegrating relationship.
{bf:2} estimates y = b1*x + b2*x^2 (+ controls).
{bf:3} adds b3*x^3.
Default is {bf:2}.
{p_end}

{phang}
{opt poly(varname)} specifies which independent variable receives the polynomial
expansion. The variable must appear in {it:regressors}. All other regressors are
included linearly as controls. If omitted, the first regressor is expanded.
{p_end}

{dlgtab:Deterministic Components}

{phang}
{opt trend(#)} ({it:mg only}) controls the deterministic specification for
detrending individual series.
{bf:1} = individual intercepts only (demeaning).
{bf:2} = individual intercepts + individual linear time trends.
Default is {bf:1}.
{p_end}

{phang}
{opt effects(string)} ({it:pmg only}) controls the fixed-effects removal.
{bf:oneway} = individual fixed effects.
{bf:twoway} = individual + time fixed effects.
Default is {bf:oneway}.
{p_end}

{dlgtab:HAC Estimation}

{phang}
{opt kernel(string)} selects the kernel function for HAC long-run variance estimation.
Available kernels: {bf:ba} (Bartlett, default), {bf:tr} (Truncated),
{bf:pa} (Parzen), {bf:bo} (Bohman), {bf:da} (Daniell), {bf:qs} (Quadratic Spectral).
{p_end}

{phang}
{opt bw(string)} selects the bandwidth. {bf:And91} uses the data-driven bandwidth
selector of Andrews (1991) (default). Alternatively, specify a positive integer.
{p_end}

{dlgtab:Advanced}

{phang}
{opt corrrob} ({it:mg only}) computes the cross-sectional correlation robust VCV
matrix. This uses the full 2N x 2N long-run variance matrix to account for
contemporaneous correlation across panels. Recommended for macro panels where
cross-sectional dependence is expected.
{p_end}

{phang}
{opt graph} produces a comprehensive suite of publication-quality diagnostic plots.
For the mg model, up to 7 graphs are produced: polynomial fit, panel-by-panel scatter,
kernel density of coefficients, caterpillar (sorted bar) plots, box plots,
residual diagnostics, and turning point visualization. For pmg, 4 graphs are
produced (fit, panel scatter, residuals, and turning point). All graphs are
combined into a single diagnostic suite.
{p_end}

{phang}
{opt level(#)} sets the confidence level for the estimation table and turning
point analysis. Default is 95.
{p_end}


{marker advanced}{...}
{title:Advanced Output}

{pstd}
{cmd:xtpcmg} produces the following advanced analysis tables after the main estimation results:
{p_end}

{dlgtab:Individual Coefficient Table (mg only)}

{pstd}
Displays each panel's individual FM-OLS coefficient estimates for the polynomial terms.
This allows direct inspection of cross-sectional heterogeneity in the estimated relationship.
{p_end}

{dlgtab:Coefficient Heterogeneity Analysis (mg only)}

{pstd}
{bf:Descriptive Statistics:} Reports the mean, median, standard deviation, interquartile range (IQR),
skewness, and kurtosis of the distribution of individual panel coefficients for each regressor.
{p_end}

{pstd}
{bf:Percentile Distribution:} Reports the minimum, 5th, 25th, 75th, 95th percentiles, and maximum
of individual panel coefficients.
{p_end}

{dlgtab:Swamy (1970) Slope Homogeneity Test (mg only)}

{pstd}
Tests the null hypothesis that all individual FM-OLS slope coefficients are equal against the
alternative that at least one panel has a different slope. The S-statistic follows a chi-squared
distribution with (N-1)*K degrees of freedom under the null. A rejection (p < 0.05) suggests
significant heterogeneity, supporting the use of Group-Mean over Pooled FM-OLS.
{p_end}

{dlgtab:Between-Within Variance Decomposition (mg only)}

{pstd}
Decomposes the total variance of individual panel coefficients into between-panel variance
(systematic heterogeneity) and within-panel estimation noise. The ratio of between-panel to total
variance indicates the strength of the heterogeneity signal. A ratio > 0.8 indicates high
systematic heterogeneity; < 0.5 indicates mostly estimation noise.
{p_end}

{dlgtab:Turning Point Analysis}

{pstd}
For quadratic models (q=2), computes the turning point x* = -b1/(2*b2) with delta-method standard
errors and 95% confidence interval. Identifies whether the relationship is concave (inverted U) or
convex (U-shaped). For cubic models (q=3), reports both critical points when they exist.
{p_end}


{marker graphs}{...}
{title:Diagnostic Graphs}

{pstd}
When {opt graph} is specified, {cmd:xtpcmg} generates a comprehensive diagnostic suite:
{p_end}

{p 8 12 2}
{bf:1. Polynomial Fit:} Scatter plot of observed data with the estimated FM-OLS polynomial curve overlaid.{break}
{bf:2. Panel-by-Panel Scatter:} Small multiples showing each panel's data and the estimated curve.{break}
{bf:3. Coefficient Density} (mg only): Kernel density plots of individual FM-OLS coefficient distributions.{break}
{bf:4. Caterpillar Plot} (mg only): Sorted bar charts of individual panel coefficients with the group-mean reference line.{break}
{bf:5. Box Plot} (mg only): Box-and-whisker plots summarising the coefficient distribution across panels.{break}
{bf:6. Residual Distribution:} Histogram of FM-OLS residuals with kernel density overlay.{break}
{bf:7. Turning Point} (when applicable): Fitted curve with the estimated turning point and confidence interval marked.
{p_end}


{marker stored}{...}
{title:Stored Results}

{pstd}
{cmd:xtpcmg} stores the following in {cmd:e()}:
{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(q)}}polynomial degree{p_end}
{synopt:{cmd:e(n_controls)}}number of linear control variables (if any){p_end}
{synopt:{cmd:e(tp)}}turning point estimate (q=2){p_end}
{synopt:{cmd:e(tp_se)}}turning point standard error (q=2){p_end}
{synopt:{cmd:e(tp_lo)}}turning point lower 95% CI bound (q=2){p_end}
{synopt:{cmd:e(tp_hi)}}turning point upper 95% CI bound (q=2){p_end}
{synopt:{cmd:e(tp_z)}}turning point z-statistic (q=2){p_end}
{synopt:{cmd:e(tp_p)}}turning point p-value (q=2){p_end}
{synopt:{cmd:e(tp1)}}first critical point (q=3){p_end}
{synopt:{cmd:e(tp2)}}second critical point (q=3){p_end}
{synopt:{cmd:e(swamy_s)}}Swamy S-statistic (mg only){p_end}
{synopt:{cmd:e(swamy_df)}}Swamy degrees of freedom (mg only){p_end}
{synopt:{cmd:e(swamy_p)}}Swamy p-value (mg only){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpcmg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}model description{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(model)}}{cmd:mg} or {cmd:pmg}{p_end}
{synopt:{cmd:e(polyvar)}}polynomial variable name{p_end}
{synopt:{cmd:e(controls)}}list of control variables (if any){p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(indiv_b)}}N x K matrix of individual FM-OLS coefficients (mg only){p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}{bf:Example 1:} Group-Mean quadratic EKC with robust VCV and graphs{p_end}
{phang2}{cmd:. xtpcmg lCO2 lGDP, model(mg) q(2) trend(1) bw(And91) corrrob graph}{p_end}

{pstd}{bf:Example 2:} Pooled cubic with two-way fixed effects and Bartlett kernel{p_end}
{phang2}{cmd:. xtpcmg lCO2 lGDP, model(pmg) q(3) effects(twoway) kernel(ba) graph}{p_end}

{pstd}{bf:Example 3:} Multiple regressors — polynomial on lGDP, linear controls lTrade and lPop{p_end}
{phang2}{cmd:. xtpcmg lCO2 lGDP lTrade lPop, model(mg) poly(lGDP) q(2) corrrob graph}{p_end}

{pstd}{bf:Example 4:} Pooled cubic with one linear control{p_end}
{phang2}{cmd:. xtpcmg lCO2 lGDP lTrade, model(pmg) poly(lGDP) q(3) effects(oneway) graph}{p_end}

{pstd}{bf:Example 5:} Access stored results after estimation{p_end}
{phang2}{cmd:. xtpcmg y x, model(mg) q(2) bw(And91)}{p_end}
{phang2}{cmd:. di "Turning point = " e(tp)}{p_end}
{phang2}{cmd:. di "Swamy p-value = " e(swamy_p)}{p_end}
{phang2}{cmd:. matrix list e(indiv_b)}{p_end}
{phang2}{cmd:. ereturn list}{p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. (1991). Heteroskedasticity and autocorrelation consistent covariance matrix
estimation. {it:Econometrica, 59(3), 817-858.}
{p_end}

{phang}
de Jong, R. M., & Wagner, M. (2022). Panel cointegrating polynomial regression analysis and
an illustration with the environmental Kuznets curve.
{it:Econometrics and Statistics.}
{p_end}

{phang}
Swamy, P. A. V. B. (1970). Efficient inference in a random coefficient regression model.
{it:Econometrica, 38(2), 311-323.}
{p_end}

{phang}
Wagner, M., & Reichold, K. (2023). Panel cointegrating polynomial regressions: group-mean
fully modified OLS estimation and inference.
{it:Econometric Reviews, 42(4), 358-392.}
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{p_end}
