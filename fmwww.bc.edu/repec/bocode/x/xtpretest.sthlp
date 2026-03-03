{smcl}
{* *! version 1.0.0  March 2026}{...}
{vieweralsosee "xthst" "help xthst"}{...}
{vieweralsosee "xtbhst" "help xtbhst"}{...}
{vieweralsosee "xtcd2" "help xtcd2"}{...}
{vieweralsosee "xtbreak" "help xtbreak"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpretest##syntax"}{...}
{viewerjumpto "Description" "xtpretest##description"}{...}
{viewerjumpto "Options" "xtpretest##options"}{...}
{viewerjumpto "Modules" "xtpretest##modules"}{...}
{viewerjumpto "Recommendation Logic" "xtpretest##recommend"}{...}
{viewerjumpto "Diagnostic Graphs" "xtpretest##graphs"}{...}
{viewerjumpto "Stored results" "xtpretest##stored"}{...}
{viewerjumpto "Dependencies" "xtpretest##dependencies"}{...}
{viewerjumpto "Examples" "xtpretest##examples"}{...}
{viewerjumpto "References" "xtpretest##references"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:xtpretest} {hline 2}}Comprehensive Panel Data Pre-Testing Suite{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpretest} {depvar} {indepvars} [{it:if}] [{it:in}]{cmd:,} [{it:options}]
{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Test Selection}
{synopt:{opt all}}run all available tests (default if no specific module selected){p_end}
{synopt:{opt hs:iao}}Hsiao (2014) ANCOVA homogeneity tests (standard F-tests){p_end}
{synopt:{opt rob:ust}}Hsiao robust HC1 heteroscedasticity-consistent Wald tests{p_end}
{synopt:{opt sum:mary}}panel summary statistics (xtsum-style decomposition){p_end}
{synopt:{opt het:erogeneity}}coefficient heterogeneity analysis with Swamy (1970) test{p_end}
{synopt:{opt slope:homogeneity}}slope homogeneity tests via {cmd:xthst} and {cmd:xtbhst}{p_end}
{synopt:{opt csd}}cross-sectional dependence tests via {cmd:xtcd2} and built-in CD{p_end}
{synopt:{opt break:s}}structural break test via {cmd:xtbreak}{p_end}

{syntab:Output Control}
{synopt:{opt gr:aph}}generate comprehensive diagnostic graphs (up to 15 graph types){p_end}
{synopt:{opt not:able}}suppress table output (stored results still available){p_end}

{syntab:Bootstrap Options}
{synopt:{opt reps(#)}}number of bootstrap replications for {cmd:xtbhst}; default is {cmd:reps(200)}{p_end}
{synopt:{opt seed(#)}}random number seed for reproducibility of bootstrap results{p_end}
{synoptline}
{p 4 6 2}
Data must be {help xtset} before using {cmd:xtpretest}. The panel must be
strongly balanced with no gaps.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpretest} provides a comprehensive suite of panel data pre-tests in a single
command, covering eight modules of diagnostic analysis. It combines homogeneity
testing, summary statistics, coefficient heterogeneity analysis, slope homogeneity
tests, cross-sectional dependence diagnostics, structural break detection, and
diagnostic visualisation into one unified framework.{p_end}

{pstd}
The command helps researchers determine the appropriate panel estimator before
estimation by systematically testing for:{p_end}

{phang2}(i) Poolability — whether data can be pooled across panels (Modules 2, 3){p_end}
{phang2}(ii) Slope heterogeneity — whether coefficients vary across panels (Modules 4, 5){p_end}
{phang2}(iii) Cross-sectional dependence — whether residuals are correlated across panels (Module 6){p_end}
{phang2}(iv) Structural breaks — whether parameters are stable over time (Module 7){p_end}

{pstd}
The command integrates methods from Hsiao (2014), Pesaran and Yamagata (2008),
Blomquist and Westerlund (2015), Pesaran (2004, 2015, 2021), Swamy (1970),
Okui and Yanagi (2019), Breusch and Pagan (1979), Karavias, Narayan, and
Westerlund (2021), and Bai and Perron (1998, 2003). It auto-detects which
companion packages are installed and runs them when available.{p_end}

{pstd}
After running all selected modules, {cmd:xtpretest} produces an {bf:Overall Pre-Test
Summary} with a decision-tree-based estimator recommendation (see
{help xtpretest##recommend:Recommendation Logic}).{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Test Selection}

{phang}
{opt all} runs all available modules (1 through 7). This is the default if no
specific module option is specified.{p_end}

{phang}
{opt hsiao} runs Module 2: Hsiao (2014) standard ANCOVA F-tests for poolability,
including F1 (overall homogeneity), F2 (slope homogeneity), and F3 (intercept
homogeneity conditional on equal slopes).{p_end}

{phang}
{opt robust} runs Module 3: Hsiao robust heteroscedasticity-consistent (HC1)
Wald tests. These provide valid inference under heteroscedasticity and also
report Breusch-Pagan (1979) diagnostics.{p_end}

{phang}
{opt summary} runs Module 1: Panel summary statistics with Overall/Between/Within
variance decomposition for each variable.{p_end}

{phang}
{opt heterogeneity} runs Module 4: Individual-level coefficient analysis,
heterogeneity statistics, variance decomposition, and the Swamy (1970) test
for parameter heterogeneity.{p_end}

{phang}
{opt slopehomogeneity} runs Module 5: Pesaran and Yamagata (2008) Delta test
via {cmd:xthst} and Blomquist and Westerlund (2015) bootstrap Delta test via
{cmd:xtbhst}, if installed.{p_end}

{phang}
{opt csd} runs Module 6: Cross-sectional dependence tests. Uses {cmd:xtcd2} for
the Pesaran (2015, 2021) CD/CDw/CD* tests and also computes a built-in
Pesaran (2004) CD test on fixed-effects residuals.{p_end}

{phang}
{opt breaks} runs Module 7: Structural break detection using {cmd:xtbreak test}
(Karavias, Narayan and Westerlund 2021; Bai and Perron 1998, 2003), if installed.
Tests for one structural break under hypothesis H1 (supF test).{p_end}

{dlgtab:Output Control}

{phang}
{opt graph} generates up to 15 diagnostic graphs covering variation decomposition,
distributions, box plots, scatter plots, residual diagnostics, coefficient
distributions, radar charts, and heterogeneity plotmeans. See
{help xtpretest##graphs:Diagnostic Graphs}.{p_end}

{phang}
{opt notable} suppresses all tabular output. Stored results in {cmd:r()} remain
available for programmatic use.{p_end}

{dlgtab:Bootstrap Options}

{phang}
{opt reps(#)} specifies the number of bootstrap replications used by {cmd:xtbhst}
in Module 5. Default is 200.{p_end}

{phang}
{opt seed(#)} sets the random number seed for bootstrap reproducibility. If not
specified or set to -1, Stata's current random state is used.{p_end}

{marker modules}{...}
{title:Modules}

{dlgtab:Module 1: Panel Summary Statistics}

{pstd}
Produces an {cmd:xtsum}-style decomposition table showing {bf:Overall},
{bf:Between} (cross-panel), and {bf:Within} (time) variation for each variable
in the model. Reports Mean, Std.Dev, Min, and Max for each component.{p_end}

{pstd}
Also produces a {bf:Pairwise Correlation Matrix} with color-coded coefficients
(|r| >= 0.7 in red, |r| >= 0.4 in yellow) and a separate {bf:P-values} table.{p_end}

{pstd}
A {bf:Missing Data Analysis} table reports Total Obs, Non-Missing, Missing
count, Missing %, and a status classification (Complete, Low < 5%, Moderate
5-20%, High >= 20%) for each variable. High missingness is flagged in red.{p_end}

{pstd}
An {bf:Outlier Detection} table uses the IQR method to identify observations
outside [Q1 - 1.5*IQR, Q3 + 1.5*IQR]. Reports Q1, Q3, IQR, outlier count,
and outlier % for each variable. High outlier rates (>= 10%) are flagged
in red; moderate (>= 5%) in yellow.{p_end}

{pstd}
This decomposition is useful for assessing how much variation exists across
panels versus within panels over time, which informs the choice between
between-effects, fixed-effects, and random-effects estimators.{p_end}

{dlgtab:Module 2: Hsiao Standard Homogeneity Tests (ANCOVA)}

{pstd}
Implements the three sequential F-tests from Hsiao (2014, Ch.2) using the
classical ANCOVA approach with three nested models:{p_end}

{phang2}{bf:Model 1 — Unrestricted}: Individual OLS regressions per panel unit
(RSS = S1, df = N(T-K-1)).{p_end}

{phang2}{bf:Model 2 — Fixed Effects}: Common slopes with different intercepts
(RSS = S2, df = N(T-1)-K).{p_end}

{phang2}{bf:Model 3 — Fully Pooled}: Common slopes and intercepts
(RSS = S3, df = NT-(K+1)).{p_end}

{pstd}
Three F-tests are computed:{p_end}

{phang2}{bf:F1 (Overall homogeneity)}: H0: slopes and intercepts are equal
across all panels. Compares S3 to S1. Rejection suggests panel-specific
parameters are needed.{p_end}

{phang2}{bf:F2 (Slope homogeneity)}: H0: slope coefficients are equal across
panels, allowing intercepts to differ. Compares S2 to S1. Rejection suggests
heterogeneous slope estimators (MG, PMG, CCE).{p_end}

{phang2}{bf:F3 (Intercept homogeneity | equal slopes)}: Conditional on equal
slopes, H0: intercepts are equal. Compares S3 to S2. Rejection suggests
fixed-effects (FE) specification.{p_end}

{pstd}
Follows the three-step decision procedure of Kuh (1963):{p_end}

{phang2}Step 1: Test F1. If accepted, use Pooled OLS.{p_end}
{phang2}Step 2: If F1 rejected, test F2. If rejected, use MG/PMG/CCE.{p_end}
{phang2}Step 3: If F2 accepted, test F3. If rejected, use FE. If accepted, use Pooled OLS.{p_end}

{pstd}
Displays an ANCOVA table (RSS, df, Mean Squares), hypothesis test results,
and a structured decision summary.{p_end}

{dlgtab:Module 3: Hsiao Robust HC Tests}

{pstd}
Same three hypotheses as Module 2 but using HC1-robust (White, 1980) standard
errors via Stata's {cmd:vce(robust)}. Uses interaction-based Wald tests:{p_end}

{phang2}{bf:Robust F1}: Tests joint significance of all panel dummies and
slope interactions (overall homogeneity).{p_end}

{phang2}{bf:Robust F2}: Tests joint significance of slope interaction terms
only (slope homogeneity).{p_end}

{phang2}{bf:Robust F3}: Tests joint significance of panel dummies with common
slopes (intercept homogeneity).{p_end}

{pstd}
These tests are valid under heteroscedasticity and provide a robust alternative
to the classical F-tests in Module 2.{p_end}

{pstd}
Also reports the {bf:Breusch-Pagan (1979)} test for heteroscedasticity in the
pooled model, informing whether robust standard errors are necessary.{p_end}

{dlgtab:Module 4: Coefficient Heterogeneity Analysis}

{pstd}
Runs individual OLS regressions for each panel unit and produces three tables:{p_end}

{phang2}{bf:Table 1 — Individual Panel Coefficients}: Full N x (K+1) table of
panel-specific intercept and slope estimates.{p_end}

{phang2}{bf:Table 2 — Heterogeneity Statistics}: Distribution summary of each
coefficient across panels — Mean, Median, Std.Dev, IQR, Skewness, Kurtosis,
Min, Max. Provides a measure of how dispersed coefficients are.{p_end}

{phang2}{bf:Table 3 — Variance Decomposition}: Decomposes total coefficient
variance into Between-panel variance (true heterogeneity) and Within-panel
variance (estimation noise from each panel's SE). Reports the signal ratio
(Between/Total) with classification: High (>= 0.8), Moderate (>= 0.5),
or Low (< 0.5).{p_end}

{pstd}
Also computes the {bf:Swamy (1970) chi-squared test} for parameter heterogeneity,
which tests whether individual slope coefficients significantly differ from the
pooled fixed-effects estimator. The test statistic is:{p_end}

{pmore}
chi2 = sum_i (b_i - b_FE)' * V_i^(-1) * (b_i - b_FE)
{p_end}

{pstd}
where b_i is the individual OLS estimate for panel i, b_FE is the pooled FE
estimate, and V_i is the variance of b_i. Under H0 of homogeneous slopes,
the statistic is chi-squared with K*(N-1) degrees of freedom.{p_end}

{dlgtab:Module 5: Slope Homogeneity Tests}

{pstd}
Auto-runs two complementary slope homogeneity tests if their packages are
installed:{p_end}

{phang2}{bf:5.1 Pesaran and Yamagata (2008) — xthst}: Reports the Delta and
adjusted Delta statistics with asymptotic p-values. The Delta test is based on
the standardised dispersion of individual slope estimates around the pooled
estimator. The adjusted version corrects for small-sample bias.{p_end}

{phang2}{bf:5.2 Blomquist and Westerlund (2015) — xtbhst}: A bootstrap version
of the Delta test that provides more reliable inference in small samples,
particularly when T is small relative to N. Uses block bootstrap for proper
handling of temporal dependence. The number of bootstrap replications is
controlled by {opt reps(#)}.{p_end}

{pstd}
Both tests share H0: slope coefficients are homogeneous across panels.
Rejection indicates the need for heterogeneous-coefficient estimators.{p_end}

{dlgtab:Module 6: Cross-Sectional Dependence}

{pstd}
Tests for cross-sectional dependence in both the raw model variables and
the regression residuals:{p_end}

{phang2}{bf:6.1 Pesaran (2015, 2021) CD Test for Variables — xtcd2}: Runs
{cmd:xtcd2} on all variables in the model (dependent and independent) to test
for cross-sectional dependence in the raw data. Reports CD, CDw, CDw+, and
CD* statistics for each variable. This reveals whether the variables themselves
exhibit strong cross-sectional dependence that could affect estimation.{p_end}

{phang2}{bf:6.2 Pesaran (2015, 2021) CD Test for FE Residuals — xtcd2}: Runs
{cmd:xtcd2} on fixed-effects residuals. Cross-sectional dependence in the
residuals implies that an unobserved common factor structure is present, which
invalidates standard FE or pooled inference.{p_end}

{phang2}{bf:6.3 Built-in Pesaran (2004) CD Test — Residuals}: Computes the CD
test statistic from fixed-effects residuals using the formula:{p_end}

{pmore}
CD = sqrt(2T / (N(N-1))) * sum_{i<j} rho_{ij}
{p_end}

{pstd}
where rho_{ij} is the pairwise sample correlation of residuals between panels
i and j. Also reports the average absolute pairwise correlation |rho_ij|.
Under H0 of cross-sectional independence, CD ~ N(0,1).{p_end}

{pstd}
If cross-sectional dependence is detected, estimators that account for common
factors are recommended: CCEMG (Pesaran 2006), CCE (Chudik and Pesaran 2015),
or FE with Driscoll-Kraay (1998) standard errors.{p_end}

{dlgtab:Module 7: Structural Breaks}

{pstd}
Tests for structural breaks in the panel regression relationship using
{cmd:xtbreak test} (Ditzen, Karavias and Westerlund 2024).{p_end}

{pstd}
Runs {cmd:xtbreak test {it:depvar} {it:indepvars}, hypothesis(1) breaks(1)}
which tests H0: no structural breaks vs H1: one structural break using the
supF statistic. Critical values from Bai and Perron (1998, 2003) are reported
at the 1%, 5%, and 10% significance levels.{p_end}

{pstd}
If a break is detected, the estimated break date is reported. Trimming is
automatically adjusted if necessary (default 15%, increased to 20% when the
minimal segment length is shorter than the number of regressors).{p_end}

{pstd}
{bf:Note:} The {cmd:xtbreak} package may display harmless "Unknown #command"
warnings during loading on some systems — these come from Python comment lines
in {cmd:xtbreak_auxiliary.ado} and do not affect results.{p_end}

{marker recommend}{...}
{title:Recommendation Logic}

{pstd}
After executing all selected modules, {cmd:xtpretest} produces an {bf:Overall
Pre-Test Summary} and an automatic estimator recommendation based on the
following decision tree:{p_end}

{phang2}1. Start with {it:Pooled OLS} as the baseline.{p_end}

{phang2}2. If Hsiao F2 (slopes) is significant (p < 0.05), recommend
{it:Mean Group (MG) / CCEMG}.{p_end}

{phang2}3. Else if Hsiao F3 (intercepts) is significant, recommend
{it:Fixed Effects (FE)}.{p_end}

{phang2}4. Override with robust results: if Robust F2 is significant and not
already MG, switch to {it:MG / CCEMG}. If Robust F3 is significant and still
Pooled OLS, switch to {it:FE}.{p_end}

{phang2}5. Override with Swamy: if Swamy test is significant and still Pooled
OLS, switch to {it:FE}.{p_end}

{phang2}6. Adjust for cross-sectional dependence: If CD test is significant:{p_end}
{phang3}— If current recommendation is MG → switch to {it:CCEMG (with CSD)}{p_end}
{phang3}— If current recommendation is FE → switch to {it:FE with Driscoll-Kraay SE}{p_end}

{pstd}
The recommendation is stored in {cmd:r(recommendation)} for programmatic use.{p_end}

{marker graphs}{...}
{title:Diagnostic Graphs}

{pstd}
When {opt graph} is specified, {cmd:xtpretest} generates up to 15 diagnostic
graphs. Each graph is created as a named Stata graph object and can be
redisplayed using {cmd:graph display {it:name}}.{p_end}

{p2colset 5 32 34 2}{...}
{p2col:{bf:Graph}}{bf:Description}{p_end}
{p2line}
{p2col:{cmd:xtpre_variation}}Between vs Within variation bar chart — shows the standard
deviation decomposition for each variable{p_end}
{p2col:{cmd:xtpre_distributions}}Variable distributions with kernel density overlays
and mean reference lines (combined, up to 6 variables){p_end}
{p2col:{cmd:xtpre_boxplots}}Cross-panel box plots by panel unit for each
variable{p_end}
{p2col:{cmd:xtpre_timeseries}}Time series line plots by panel (separate
panel lines via {cmd:by()}){p_end}
{p2col:{cmd:xtpre_scatter}}Scatter plots of {depvar} vs each {indepvar} with
linear and quadratic fit lines overlaid{p_end}
{p2col:{cmd:xtpre_corrmatrix}}Pairwise scatter matrix of all variables in
the model{p_end}
{p2col:{cmd:xtpre_residuals}}Residual diagnostics panel: residuals vs fitted
values, residual histogram with kernel density, and residual box plots by panel
(using pooled OLS residuals){p_end}
{p2col:{cmd:xtpre_csdisp}}Cross-sectional dispersion over time — panel SD
and mean of each variable by time period{p_end}
{p2col:{cmd:xtpre_coefdist}}Coefficient distribution kernel densities —
shows the distribution of each individual slope estimate across panels
(requires {opt heterogeneity} or {opt all}){p_end}
{p2col:{cmd:xtpre_hsiao}}Hsiao F-test summary bar chart — F1, F2, F3 with
5% critical value line (requires {opt hsiao} or {opt all}){p_end}
{p2col:{cmd:xtpre_panelmeans}}Mean of dependent variable by panel — bar chart
(requires {opt summary} or {opt all}){p_end}
{p2col:{cmd:xtpre_radar}}Coefficient heterogeneity radar chart — grouped bar
chart showing Mean, Std.Dev, Min, Max of individual coefficients across panels
(requires {opt heterogeneity} or {opt all}){p_end}
{p2col:{cmd:xtpre_plotmeans}}Panel means with 95% confidence intervals — bar
chart with error bars highlighting mean-level heterogeneity{p_end}
{p2col:{cmd:xtpre_plotmeans_panel}}Heterogeneity across panels — R-style
connected line plot with confidence intervals (plotmeans-style){p_end}
{p2col:{cmd:xtpre_plotmeans_time}}Heterogeneity across time periods — R-style
connected line plot with confidence intervals (plotmeans-style){p_end}
{p2colreset}{...}

{pstd}
Use {cmd:graph display {it:name}} to redisplay any graph, or
{cmd:graph export {it:name}.png, name({it:name}) replace} to save.{p_end}

{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtpretest} stores the following in {cmd:r()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}

{p2col 5 24 28 2: {it:Module 1 — Summary Statistics}}{p_end}
{synopt:{cmd:r(xtsum_overall_mean)}}overall mean of dependent variable{p_end}
{synopt:{cmd:r(xtsum_overall_sd)}}overall standard deviation of dependent variable{p_end}

{p2col 5 24 28 2: {it:Module 2 — Hsiao Standard F-Tests}}{p_end}
{synopt:{cmd:r(F1)}}F1 statistic (overall homogeneity: slopes + intercepts){p_end}
{synopt:{cmd:r(F1_p)}}p-value for F1{p_end}
{synopt:{cmd:r(F1_df1)}}numerator degrees of freedom for F1{p_end}
{synopt:{cmd:r(F1_df2)}}denominator degrees of freedom for F1{p_end}
{synopt:{cmd:r(F2)}}F2 statistic (slope homogeneity){p_end}
{synopt:{cmd:r(F2_p)}}p-value for F2{p_end}
{synopt:{cmd:r(F2_df1)}}numerator degrees of freedom for F2{p_end}
{synopt:{cmd:r(F2_df2)}}denominator degrees of freedom for F2{p_end}
{synopt:{cmd:r(F3)}}F3 statistic (intercept homogeneity given equal slopes){p_end}
{synopt:{cmd:r(F3_p)}}p-value for F3{p_end}
{synopt:{cmd:r(F3_df1)}}numerator degrees of freedom for F3{p_end}
{synopt:{cmd:r(F3_df2)}}denominator degrees of freedom for F3{p_end}
{synopt:{cmd:r(S1)}}unrestricted RSS (sum of individual panel regressions){p_end}
{synopt:{cmd:r(S2)}}fixed-effects model RSS{p_end}
{synopt:{cmd:r(S3)}}pooled OLS model RSS{p_end}

{p2col 5 24 28 2: {it:Module 3 — Hsiao Robust HC Tests}}{p_end}
{synopt:{cmd:r(rF1)}}Robust F1 statistic (overall homogeneity){p_end}
{synopt:{cmd:r(rF1_p)}}p-value for robust F1{p_end}
{synopt:{cmd:r(rF2)}}Robust F2 statistic (slope homogeneity){p_end}
{synopt:{cmd:r(rF2_p)}}p-value for robust F2{p_end}
{synopt:{cmd:r(rF3)}}Robust F3 statistic (intercept homogeneity){p_end}
{synopt:{cmd:r(rF3_p)}}p-value for robust F3{p_end}
{synopt:{cmd:r(bp_chi2)}}Breusch-Pagan chi-squared statistic{p_end}
{synopt:{cmd:r(bp_p)}}Breusch-Pagan p-value{p_end}

{p2col 5 24 28 2: {it:Module 4 — Coefficient Heterogeneity}}{p_end}
{synopt:{cmd:r(swamy_chi2)}}Swamy (1970) test chi-squared statistic{p_end}
{synopt:{cmd:r(swamy_df)}}Swamy test degrees of freedom = K*(N-1){p_end}
{synopt:{cmd:r(swamy_p)}}Swamy test p-value{p_end}

{p2col 5 24 28 2: {it:Module 5 — Slope Homogeneity (if xthst installed)}}{p_end}
{synopt:{cmd:r(delta_xthst)}}Delta statistic from xthst{p_end}
{synopt:{cmd:r(delta_adj_xthst)}}adjusted Delta statistic from xthst{p_end}
{synopt:{cmd:r(delta_p_xthst)}}p-value for Delta from xthst{p_end}
{synopt:{cmd:r(delta_adj_p_xthst)}}p-value for adjusted Delta from xthst{p_end}

{p2col 5 24 28 2: {it:Module 5 — Slope Homogeneity (if xtbhst installed)}}{p_end}
{synopt:{cmd:r(delta_xtbhst)}}Delta statistic from xtbhst{p_end}
{synopt:{cmd:r(delta_adj_xtbhst)}}adjusted Delta statistic from xtbhst{p_end}
{synopt:{cmd:r(delta_p_xtbhst)}}bootstrap p-value for Delta from xtbhst{p_end}
{synopt:{cmd:r(delta_adj_p_xtbhst)}}bootstrap p-value for adjusted Delta{p_end}

{p2col 5 24 28 2: {it:Module 6 — Cross-Sectional Dependence (if xtcd2 installed)}}{p_end}
{synopt:{cmd:r(cd)}}CD statistic from xtcd2{p_end}
{synopt:{cmd:r(cd_p)}}CD p-value from xtcd2{p_end}
{synopt:{cmd:r(cd_rho)}}average correlation from xtcd2{p_end}

{p2col 5 24 28 2: {it:Module 6 — Cross-Sectional Dependence (built-in)}}{p_end}
{synopt:{cmd:r(cd_builtin)}}built-in Pesaran (2004) CD test statistic{p_end}
{synopt:{cmd:r(cd_builtin_p)}}built-in CD test p-value{p_end}
{synopt:{cmd:r(avg_rho)}}average absolute pairwise correlation |rho_ij|{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable names{p_end}
{synopt:{cmd:r(recommendation)}}recommended estimator based on test results{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(indiv_b)}}N x (K+1) matrix of individual panel coefficients (from Module 4){p_end}

{marker dependencies}{...}
{title:Dependencies}

{pstd}
{cmd:xtpretest} requires Stata 14.0 or later. The following companion packages
are {bf:optional} — the command auto-detects their availability and skips
any module whose dependency is not installed:{p_end}

{p2colset 5 24 26 2}{...}
{p2col:{bf:Package}}{bf:Used in / Purpose}{p_end}
{p2line}
{p2col:{cmd:xthst}}Module 5: Pesaran and Yamagata (2008) Delta test for slope
homogeneity{p_end}
{p2col:}{stata "ssc install xthst":ssc install xthst}{p_end}
{p2col:{cmd:xtbhst}}Module 5: Blomquist and Westerlund (2015) bootstrap
Delta test{p_end}
{p2col:}{stata "ssc install xtbhst":ssc install xtbhst}{p_end}
{p2col:{cmd:xtcd2}}Module 6: Pesaran (2015, 2021) and related CSD tests{p_end}
{p2col:}{stata "ssc install xtcd2":ssc install xtcd2}{p_end}
{p2col:{cmd:xtbreak}}Module 7: Structural break testing (Ditzen, Karavias and
Westerlund 2024). Requires {cmd:moremata}.{p_end}
{p2col:}{stata "ssc install xtbreak":ssc install xtbreak}{p_end}
{p2col:}{stata "ssc install moremata":ssc install moremata}{p_end}
{p2colreset}{...}

{pstd}
Install all optional dependencies at once:{p_end}
{phang2}{cmd:. ssc install xthst}{p_end}
{phang2}{cmd:. ssc install xtbhst}{p_end}
{phang2}{cmd:. ssc install xtcd2}{p_end}
{phang2}{cmd:. ssc install moremata}{p_end}
{phang2}{cmd:. ssc install xtbreak}{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Basic usage — run all pre-tests:}{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock}{p_end}

{pstd}{bf:Only Hsiao homogeneity tests:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, hsiao}{p_end}

{pstd}{bf:Hsiao standard + robust with diagnostic graphs:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, hsiao robust graph}{p_end}

{pstd}{bf:Panel summary statistics only:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, summary}{p_end}

{pstd}{bf:Coefficient heterogeneity with radar chart and plotmeans:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, heterogeneity graph}{p_end}

{pstd}{bf:Slope homogeneity tests with 500 bootstrap reps:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, slopehomogeneity reps(500) seed(12345)}{p_end}

{pstd}{bf:Cross-sectional dependence only:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, csd}{p_end}

{pstd}{bf:Structural break test only:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, breaks}{p_end}

{pstd}{bf:All tests with full diagnostic graphs:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, all graph}{p_end}

{pstd}{bf:Check stored results after running:}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. di "F1=" r(F1) "  F2=" r(F2) "  F3=" r(F3)}{p_end}
{phang2}{cmd:. di "Recommended: " r(recommendation)}{p_end}

{pstd}{bf:Suppress tables, keep only stored results:}{p_end}
{phang2}{cmd:. xtpretest invest mvalue kstock, notable}{p_end}
{phang2}{cmd:. return list}{p_end}

{pstd}{bf:Using with custom data:}{p_end}
{phang2}{cmd:. use mydata, clear}{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtpretest gdp fdi inflation unemployment}{p_end}

{marker references}{...}
{title:References}

{phang}
Bai, J. and Perron, P. (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66(1), pp 47-78.{p_end}

{phang}
Bai, J. and Perron, P. (2003). Computation and analysis of multiple structural
change models. {it:Journal of Applied Econometrics} 18(1), pp 1-22.{p_end}

{phang}
Blomquist, J. and Westerlund, J. (2015). Panel bootstrap tests of slope
homogeneity. {it:Empirical Economics} 48, pp 1643-1660.{p_end}

{phang}
Breusch, T.S. and Pagan, A.R. (1979). A simple test for heteroscedasticity
and random coefficient variation. {it:Econometrica} 47(5), pp 1287-1294.{p_end}

{phang}
Chudik, A. and Pesaran, M.H. (2015). Common correlated effects estimation of
heterogeneous dynamic panel data models with weakly exogenous regressors.
{it:Journal of Econometrics} 188(2), pp 393-420.{p_end}

{phang}
Ditzen, J., Karavias, Y. and Westerlund, J. (2024). Testing and estimating
structural breaks in time series and panel data in Stata.
{it:arXiv:2110.14550}.{p_end}

{phang}
Driscoll, J.C. and Kraay, A.C. (1998). Consistent covariance matrix estimation
with spatially dependent panel data. {it:Review of Economics and Statistics}
80(4), pp 549-560.{p_end}

{phang}
Fan, J., Liao, Y. and Yao, J. (2015). Power enhancement in high-dimensional
cross-sectional tests. {it:Econometrica} 83(4), pp 1497-1541.{p_end}

{phang}
Hsiao, C. (2014). {it:Analysis of Panel Data}. 3rd edition. Cambridge
University Press. Chapter 2.{p_end}

{phang}
Juodis, A. and Reese, S. (2021). The incidental parameters problem in testing
for remaining cross-section correlation. {it:Journal of Business and Economic
Statistics} 40(3), pp 1191-1203.{p_end}

{phang}
Karavias, Y., Narayan, P.K. and Westerlund, J. (2021). Structural breaks in
interactive effects panels and the stock market reaction to COVID-19.
{it:Journal of Business and Economic Statistics} 41(3), pp 653-666.{p_end}

{phang}
Kuh, E. (1963). {it:Capital Stock Growth: A Micro-Econometric Approach}.
North-Holland.{p_end}

{phang}
Okui, R. and Yanagi, T. (2019). Panel data analysis with heterogeneous
dynamics. {it:Journal of Econometrics} 212(2), pp 451-475.{p_end}

{phang}
Pesaran, M.H. (2004). General diagnostic tests for cross-section dependence
in panels. {it:CESifo Working Paper} No. 1229.{p_end}

{phang}
Pesaran, M.H. (2006). Estimation and inference in large heterogeneous panels
with a multifactor error structure. {it:Econometrica} 74(4), pp 967-1012.{p_end}

{phang}
Pesaran, M.H. (2015). Testing weak cross-sectional dependence in large
panels. {it:Econometric Reviews} 34(6-10), pp 1089-1117.{p_end}

{phang}
Pesaran, M.H. (2021). General diagnostic tests for cross-sectional dependence
in panels. {it:Empirical Economics} 60, pp 13-50.{p_end}

{phang}
Pesaran, M.H. and Xie, T. (2021). A bias-corrected CD test for error
cross-sectional dependence in panel data models with latent factors.
{it:Cambridge Working Papers in Economics} 2158.{p_end}

{phang}
Pesaran, M.H. and Yamagata, T. (2008). Testing slope homogeneity in large
panels. {it:Journal of Econometrics} 142(1), pp 50-93.{p_end}

{phang}
Swamy, P.A.V.B. (1970). Efficient inference in a random coefficient
regression model. {it:Econometrica} 38(2), pp 311-323.{p_end}

{phang}
White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator
and a direct test for heteroskedasticity. {it:Econometrica} 48(4),
pp 817-838.{p_end}

{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
xtpretest v1.0.0, March 2026.{p_end}
