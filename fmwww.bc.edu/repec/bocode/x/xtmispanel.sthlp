{smcl}
{* *! version 1.0.0  03mar2026}{...}
{viewerjumpto "Syntax" "xtmispanel##syntax"}{...}
{viewerjumpto "Description" "xtmispanel##description"}{...}
{viewerjumpto "Options" "xtmispanel##options"}{...}
{viewerjumpto "Methods" "xtmispanel##methods"}{...}
{viewerjumpto "Modules" "xtmispanel##modules"}{...}
{viewerjumpto "Graphs" "xtmispanel##graphs"}{...}
{viewerjumpto "Stored results" "xtmispanel##results"}{...}
{viewerjumpto "Important notes" "xtmispanel##notes"}{...}
{viewerjumpto "Workflow" "xtmispanel##workflow"}{...}
{viewerjumpto "Examples" "xtmispanel##examples"}{...}
{viewerjumpto "FAQ" "xtmispanel##faq"}{...}
{viewerjumpto "References" "xtmispanel##references"}{...}
{viewerjumpto "Author" "xtmispanel##author"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:xtmispanel} {hline 2}}Comprehensive Missing Data Detection, Imputation and Diagnostics for Panel Data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
{bf:1. Detection and testing (multiple variables allowed)}

{p 8 16 2}
{cmd:xtmispanel} [{varlist}] [{cmd:if}] [{cmd:in}]
  [{cmd:,} {cmd:detect} {cmd:test}]

{phang}
{bf:2. Imputation (exactly one variable required)}

{p 8 16 2}
{cmd:xtmispanel} {it:varname} [{cmd:if}] [{cmd:in}]
  {cmd:,} {cmd:impute(}{it:method}{cmd:)}
  [{cmd:generate(}{it:newvar}{cmd:)} {cmd:replace}
   {cmd:knn(}{it:#}{cmd:)} {cmd:mice(}{it:#}{cmd:)}]

{phang}
{bf:3. Sensitivity analysis (exactly one variable required)}

{p 8 16 2}
{cmd:xtmispanel} {it:varname} [{cmd:if}] [{cmd:in}]
  {cmd:,} {cmd:sensitivity}
  [{cmd:methods(}{it:method_list}{cmd:)}
   {cmd:knn(}{it:#}{cmd:)} {cmd:mice(}{it:#}{cmd:)}]

{phang}
{bf:4. Visualization (multiple variables allowed)}

{p 8 16 2}
{cmd:xtmispanel} [{varlist}] [{cmd:if}] [{cmd:in}]
  {cmd:,} {cmd:graph}
  [{cmd:impvar(}{it:varname}{cmd:)}]

{phang}
{bf:5. Combined usage}

{p 8 16 2}
{cmd:xtmispanel} [{varlist}] [{cmd:if}] [{cmd:in}]
  {cmd:,} {cmd:detect} {cmd:test}

{pstd}
{bf:Prerequisites:} Data must be declared as panel data using {cmd:xtset}
before using {cmd:xtmispanel}. The panel variable and time variable are
automatically detected from {cmd:xtset}.{p_end}

{pstd}
{bf:Default behavior:} If no option is specified, {cmd:detect} is assumed.{p_end}

{pstd}
{bf:Variable list:} If no {varlist} is specified, all numeric variables
(excluding the panel and time identifiers) are analyzed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtmispanel} is a comprehensive, all-in-one Stata command for handling
missing values in panel (time-series cross-sectional) data. It implements
the complete missing data workflow:{p_end}

{pstd}
{bf:Step 1.} Detect and summarize missingness patterns{break}
{bf:Step 2.} Test the missing data mechanism (MCAR, MAR, MNAR){break}
{bf:Step 3.} Choose and apply an imputation method{break}
{bf:Step 4.} Validate via sensitivity analysis{break}
{bf:Step 5.} Visualize results with publication-quality graphs{p_end}

{pstd}
The command is designed specifically for panel data and respects the panel
structure in all computations (panel-specific means, within-panel
interpolation, panel-aware regression, etc.).{p_end}

{pstd}
{bf:Key features:}{p_end}

{phang2}{cmd:o} 4 formatted detection tables (by variable, panel, time, pattern){p_end}
{phang2}{cmd:o} Little's MCAR test + logistic MAR tests + pattern classification{p_end}
{phang2}{cmd:o} 13 imputation methods from simple to ML-inspired{p_end}
{phang2}{cmd:o} Multi-method sensitivity analysis with automatic recommendation{p_end}
{phang2}{cmd:o} 8 publication-quality diagnostic graphs{p_end}
{phang2}{cmd:o} All imputation is panel-aware (respects panel structure){p_end}
{phang2}{cmd:o} Imputed variable is added to the dataset; original is never modified{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Module 1 — Detection}

{phang}
{opt detect} displays four formatted summary tables:{p_end}

{phang2}{bf:Table 1:} Per-variable summary — N total, N missing, % missing,
  mean, SD, and a severity status (Complete / Low / Moderate / High / Severe).{p_end}

{phang2}{bf:Table 2:} Per-panel summary — N observations, N missing, % missing,
  number of gaps, maximum gap length, and status.{p_end}

{phang2}{bf:Table 3:} Per-time-period summary — N missing, % missing, and an
  ASCII visual bar showing severity for each period.{p_end}

{phang2}{bf:Table 4:} Missing data pattern co-occurrence matrix showing which
  combinations of variables have missing values simultaneously. Shows up to
  10 variables. Pattern '.' = observed, 'X' = missing.{p_end}

{pstd}
This is the default action if no option is specified.{p_end}

{dlgtab:Module 2 — Testing}

{phang}
{opt test} runs three diagnostic tests for the missing data mechanism:{p_end}

{phang2}{bf:Test 1: Little's MCAR Test (Approximate).} Compares means of each
  variable across groups defined by missingness patterns of other variables.
  Reports chi-square statistic, degrees of freedom, and p-value.
  H0: Data are MCAR (p >= 0.05 = fail to reject).{p_end}

{phang2}{bf:Test 2: MAR Logistic Regression Test.} For each variable with
  missing values, regresses its missingness indicator (0/1) on all other
  variables. Reports chi2, p-value, Pseudo-R2, and conclusion (MCAR or MAR)
  per variable.{p_end}

{phang2}{bf:Test 3: Pattern Classification.} Determines whether the
  missingness pattern is {it:monotone} (once missing, stays missing) or
  {it:arbitrary} (irregular gaps). Monotone patterns allow sequential
  imputation; arbitrary patterns favor MICE.{p_end}

{phang2}{bf:Overall Recommendation.} Combines all test results to classify the
  mechanism as MCAR, MAR, or possibly MNAR, with method recommendations.{p_end}

{dlgtab:Module 3 — Imputation}

{phang}
{opt impute(method)} imputes missing values in the specified variable using
  the given method. {bf:Exactly one variable} must be specified.{p_end}

{pstd}
{bf:Output after imputation:}{p_end}

{phang2}{cmd:o} Fill report: missing before, values imputed, still missing, fill rate{p_end}
{phang2}{cmd:o} Before vs After comparison table: N, Mean, SD, Min, Max with Delta and Delta%{p_end}
{phang2}{cmd:o} Pearson correlation between original and imputed (on observed pairs){p_end}
{phang2}{cmd:o} Auto-generated density overlay graph ({bf:xtmis_impute_density}) comparing distributions{p_end}

{phang}
{opt generate(newvar)} specifies the name for the imputed variable.
  If not specified, the default name is {it:varname}{bf:_imp}.{p_end}

{phang}
{opt replace} allows overwriting an existing variable with the same name
  as the generated imputed variable. Without this option, the command will
  exit with an error if {it:varname_imp} already exists.{p_end}

{phang}
{opt knn(#)} specifies the number of nearest neighbors for the {bf:knn}
  method. Default is {bf:5}. Higher values produce smoother imputations
  but may over-smooth. Recommended range: 3–10.{p_end}

{phang}
{opt mice(#)} specifies the number of multiple imputations for the {bf:mice}
  method. Default is {bf:5}. More imputations improve precision but
  increase computation time. Recommended range: 5–20.{p_end}

{pstd}
{bf:Important:} The imputed variable is {bf:added to your dataset in memory}.
  The original variable is {bf:never modified}. To save permanently,
  use {cmd:save} after imputation. See {help xtmispanel##notes:Important Notes}.{p_end}

{dlgtab:Module 4 — Sensitivity}

{phang}
{opt sensitivity} runs all (or selected) imputation methods on the specified
  variable and produces a comparison table showing:{p_end}

{phang2}— Mean, SD, min, max of the imputed series{p_end}
{phang2}— Number of observations filled{p_end}
{phang2}— Percentage change in mean from the original (observed) distribution{p_end}

{pstd}
The method with the smallest absolute mean change is automatically recommended.
  Color coding: green (< 1%), yellow (1–5%), red (> 5%).{p_end}

{phang}
{opt methods(method_list)} specifies a subset of methods for sensitivity
  analysis. Separate methods with spaces. Default uses all 13 methods:
  mean median locf nocb linear spline regress pmm hotdeck knn rf em mice.{p_end}

{dlgtab:Module 5 — Visualization}

{phang}
{opt graph} generates 8 publication-quality diagnostic graphs. All graphs
  are stored in Stata memory and can be displayed or exported after the command.
  See {help xtmispanel##graphs:Graphs} for the full list.{p_end}

{phang}
{opt impvar(varname)} specifies a pre-existing imputed variable for the
  density overlay graph (Graph 6). If omitted, the command automatically
  imputes the first variable using linear interpolation to generate the
  density comparison.{p_end}


{marker methods}{...}
{title:Imputation Methods}

{pstd}
{cmd:xtmispanel} supports the following 13 panel-aware imputation methods:{p_end}

{dlgtab:Simple Methods}

{p2colset 5 18 20 2}{...}
{p2col:{bf:mean}}Panel-specific mean imputation. Replaces missing values with
  the mean of observed values in the same panel. Falls back to the global mean
  if the entire panel is missing. Fast but ignores trends.{p_end}

{p2col:{bf:median}}Panel-specific median imputation. Same as mean but uses the
  median, which is more robust to outliers.{p_end}

{p2col:{bf:locf}}Last Observation Carried Forward. Fills each missing value
  with the most recent non-missing value in the same panel. Runs up to 10
  passes for consecutive gaps. Cannot fill leading missings (first
  observations); those are left as missing.{p_end}

{p2col:{bf:nocb}}Next Observation Carried Backward. Like LOCF but fills
  backward from the next available observation. Falls back to LOCF + panel
  mean for any remaining values. Ensures 100% fill rate.{p_end}

{dlgtab:Interpolation Methods}

{p2col:{bf:linear}}Linear interpolation within each panel using Stata's
  {cmd:ipolate} command. For leading/trailing missings outside the observed
  range, falls back to LOCF and NOCB. Best for smooth trends.{p_end}

{p2col:{bf:spline}}Cubic spline interpolation with extrapolation using
  {cmd:ipolate, epolate}. Produces smoother curves than linear for
  nonlinear trends. Falls back to linear for any remaining values.{p_end}

{dlgtab:Model-Based Methods}

{p2col:{bf:regress}}Panel regression imputation. Fits a fixed-effects
  regression ({cmd:xtreg, fe}) of the variable on time, predicts missing
  values, and adds a stochastic component from the residual variance.
  Falls back to OLS with panel dummies if FE fails.{p_end}

{p2col:{bf:pmm}}Predictive Mean Matching. Fits a regression, then for each
  missing value finds the observed value whose predicted value is closest
  (the "donor"). Preserves the observed distribution better than regression.
  Falls back to panel mean if regression fails.{p_end}

{p2col:{bf:hotdeck}}Temporal hot-deck imputation. Uses the nearest observed
  value in time within the same panel (like LOCF/NOCB) and adds a small
  random perturbation (5% of panel SD) for stochastic variation.{p_end}

{dlgtab:ML-Inspired Methods}

{p2col:{bf:knn}}K-Nearest Neighbor imputation. For each missing observation,
  finds the {it:k} nearest observations in time within the same panel and
  fills with their mean. Controlled by the {opt knn(#)} option. Default k=5.{p_end}

{p2col:{bf:rf}}Random forest-style iterative regression. Initializes with
  panel mean, then iterates 5 rounds of regression using lag, lead, time,
  and panel dummies as predictors. Updates only missing values each round.
  Captures nonlinear temporal patterns.{p_end}

{p2col:{bf:em}}Expectation-Maximization algorithm. Iterates 20 rounds between
  M-step (fit regression on current complete data) and E-step (update missing
  values using conditional expectation). Uses damped updates (70/30 blend)
  for convergence stability.{p_end}

{p2col:{bf:mice}}Multiple Imputation by Chained Equations. Creates multiple
  (default 5) imputed datasets using regression with random draws, each
  initialized with mean + noise. Chains 3 rounds of equations per imputation.
  Final values are Rubin's pooled point estimates (average across imputations).
  Controlled by {opt mice(#)}.{p_end}

{pstd}
{bf:Which method to use?}{p_end}

{p2colset 5 20 22 2}{...}
{p2col:{bf:Mechanism}}Suggested Methods{p_end}
{p2line}
{p2col:{bf:MCAR}}Any method is acceptable. Simplest: {bf:mean}, {bf:linear}, {bf:locf}{p_end}
{p2col:{bf:MAR}}Model-based: {bf:mice}, {bf:pmm}, {bf:regress}, {bf:knn}, {bf:em}{p_end}
{p2col:{bf:MNAR}}Run {bf:sensitivity} across multiple methods. Consider selection models.{p_end}
{p2col:{bf:Smooth trends}}Interpolation: {bf:linear}, {bf:spline}{p_end}
{p2col:{bf:Block missing}}Temporal: {bf:locf}, {bf:nocb}, {bf:hotdeck}{p_end}
{p2col:{bf:Best overall}}Run {cmd:xtmispanel var, sensitivity} and follow the recommendation{p_end}
{p2line}


{marker modules}{...}
{title:Modules}

{pstd}
{cmd:xtmispanel} consists of 5 integrated modules:{p_end}

{p2colset 5 12 14 2}{...}
{p2col:{bf:#}}Module{p_end}
{p2line}
{p2col:{bf:1}}Detection — 4 formatted summary tables (by variable, panel, time, pattern){p_end}
{p2col:{bf:2}}Testing — MCAR test, MAR tests, pattern classification, recommendation{p_end}
{p2col:{bf:3}}Imputation — 13 methods; creates new variable in dataset{p_end}
{p2col:{bf:4}}Sensitivity — compares all methods; recommends lowest distortion{p_end}
{p2col:{bf:5}}Visualization — 8 publication-quality Stata graphs{p_end}
{p2line}

{pstd}
Modules can be combined in a single call (e.g., {cmd:detect test}) or run
separately. Module 3 (imputation) and Module 4 (sensitivity) require exactly
one variable; all other modules accept multiple variables.{p_end}


{marker graphs}{...}
{title:Graphs}

{pstd}
The {opt graph} option generates 8 diagnostic graphs:{p_end}

{p2colset 5 24 26 2}{...}
{p2col:{bf:Graph Name}}Description{p_end}
{p2line}
{p2col:{bf:xtmis_heatmap}}Missing data heatmap (panel x time). Green squares =
  observed, red squares = missing. Shows the spatial-temporal pattern of
  missingness at a glance.{p_end}
{p2col:{bf:xtmis_barvar}}Horizontal bar chart showing % missing per variable.
  X-axis always starts at 0. Color indicates severity.{p_end}
{p2col:{bf:xtmis_barpanel}}Bar chart showing % missing per panel unit across
  all variables. Identifies which panels have the most missing data.{p_end}
{p2col:{bf:xtmis_bartime}}Area chart showing % missing over time across all
  panels and variables. Reveals whether missingness is concentrated in specific
  periods (e.g., economic crises, data collection gaps).{p_end}
{p2col:{bf:xtmis_pattern}}Pattern frequency bar chart showing how many
  observations share each unique missingness pattern. Pattern rank 1 is the
  most common pattern (usually "all observed"). Limited to 20 patterns and
  variables <= 15.{p_end}
{p2col:{bf:xtmis_density}}Kernel density overlay comparing the distribution of
  the original (observed-only) data versus the complete (imputed) data.
  If no {opt impvar()} is specified, auto-imputes using linear interpolation.
  Useful for checking whether imputation distorts the distribution.{p_end}
{p2col:{bf:xtmis_timeline}}Scatter plot with circles (observed) and X marks
  (missing) for each panel-time cell. Alternative to the heatmap.{p_end}
{p2col:{bf:xtmis_combined}}4-panel combined diagnostic dashboard containing
  the heatmap, barvar, bartime, and pattern graphs.{p_end}
{p2col:{bf:xtmis_impute_density}}Auto-generated density overlay after imputation.
  Compares original observed distribution with completed (imputed) distribution.
  Created automatically when using {opt impute()}.{p_end}
{p2line}

{pstd}
{bf:Viewing and exporting graphs:}{p_end}

{phang2}{cmd:. graph display xtmis_heatmap}{p_end}
{phang2}{cmd:. graph display xtmis_combined}{p_end}
{phang2}{cmd:. graph export xtmis_heatmap.png, name(xtmis_heatmap) replace width(1200)}{p_end}
{phang2}{cmd:. graph export xtmis_combined.pdf, name(xtmis_combined) replace}{p_end}

{pstd}
All graphs use white backgrounds, clean typography, and professional color
palettes suitable for journal submissions.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtmispanel, detect} stores the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(total_missing)}}total missing values across all variables{p_end}
{synopt:{cmd:r(total_obs)}}total observation-variable pairs{p_end}
{synopt:{cmd:r(overall_pct)}}overall percentage missing{p_end}
{synopt:{cmd:r(n_panels)}}number of panels{p_end}
{synopt:{cmd:r(n_vars)}}number of variables analyzed{p_end}

{pstd}
{cmd:xtmispanel, test} stores the following in {cmd:r()}:{p_end}

{synopt:{cmd:r(mcar_chi2)}}MCAR test chi-square statistic{p_end}
{synopt:{cmd:r(mcar_df)}}MCAR test degrees of freedom{p_end}
{synopt:{cmd:r(mcar_pval)}}MCAR test p-value{p_end}
{synopt:{cmd:r(mcar_result)}}REJECT or FAIL_TO_REJECT{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(mechanism)}}classified mechanism: MCAR, MAR, or MNAR{p_end}

{pstd}
{cmd:xtmispanel, impute()} stores the following in {cmd:r()}:{p_end}

{synopt:{cmd:r(n_missing)}}number of missing values before imputation{p_end}
{synopt:{cmd:r(n_imputed)}}number of values successfully imputed{p_end}
{synopt:{cmd:r(n_remain)}}number still missing after imputation{p_end}
{synopt:{cmd:r(orig_mean)}}mean of original observed values{p_end}
{synopt:{cmd:r(orig_sd)}}SD of original observed values{p_end}
{synopt:{cmd:r(imp_mean)}}mean of imputed (complete) variable{p_end}
{synopt:{cmd:r(imp_sd)}}SD of imputed (complete) variable{p_end}
{synopt:{cmd:r(correlation)}}Pearson correlation between original and imputed{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(method)}}imputation method used{p_end}
{synopt:{cmd:r(imputed_var)}}name of generated variable{p_end}

{pstd}
{cmd:xtmispanel, sensitivity} stores the following in {cmd:r()}:{p_end}

{synopt:{cmd:r(best_method)}}recommended method name{p_end}
{synopt:{cmd:r(best_dmean_pct)}}smallest mean change percentage{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(sensitivity)}}matrix of results (methods x 5 statistics){p_end}

{pstd}
{bf:Using stored results:}

{phang2}{cmd:. xtmispanel GDP, impute(linear)}{p_end}
{phang2}{cmd:. display "Imputed " r(n_imputed) " values using " r(method)}{p_end}
{phang2}{cmd:. display "Fill rate: " (r(n_imputed)/r(n_missing))*100 "%"}{p_end}

{phang2}{cmd:. xtmispanel GDP, sensitivity}{p_end}
{phang2}{cmd:. display "Best method: " r(best_method)}{p_end}
{phang2}{cmd:. matrix list r(sensitivity)}{p_end}


{marker notes}{...}
{title:Important Notes}

{dlgtab:How imputed variables work}

{phang}
1. The imputed variable is {bf:added to your current dataset in memory} as a
   new variable. The original variable is {bf:never modified}.{p_end}

{phang}
2. By default, the imputed variable is named {it:varname}{bf:_imp}. You can
   customize this with {opt generate(newvar)}.{p_end}

{phang}
3. To save the imputed variable permanently, you must {cmd:save} the dataset
   after imputation:{p_end}

{phang2}{cmd:. xtmispanel GDP, impute(linear)}{p_end}
{phang2}{cmd:. save mydata_complete.dta, replace}{p_end}

{phang}
4. Use {opt replace} to overwrite an existing imputed variable (e.g., to try
   a different method):{p_end}

{phang2}{cmd:. xtmispanel GDP, impute(linear)}{break}
{cmd:. xtmispanel GDP, impute(mice) replace}{break}
(overwrites GDP_imp with MICE results){p_end}

{dlgtab:Sensitivity analysis}

{phang}
5. The sensitivity module creates {it:temporary} imputed variables for each
   method. These are automatically dropped. Only the comparison table and
   recommendation are retained.{p_end}

{phang}
6. The "best" method is chosen based on the {bf:smallest absolute mean change}
   from the original distribution. This is a simple criterion; users should
   also consider SD, range, and theoretical appropriateness.{p_end}

{dlgtab:Data requirements}

{phang}
7. Data must be {cmd:xtset} before using {cmd:xtmispanel}. The command
   automatically detects the panel and time variables.{p_end}

{phang}
8. The command works with both balanced and unbalanced panels.{p_end}

{phang}
9. At least 2 non-missing observations per panel are needed for most
   imputation methods to produce meaningful results.{p_end}

{phang}
10. For {bf:mice} and {bf:rf}, computation time increases with panel count.
    For very large datasets (>10,000 obs), consider using a subset of methods
    in the sensitivity analysis.{p_end}

{dlgtab:Mechanism tests}

{phang}
11. The MCAR test is an {it:approximation} of Little's (1988) test using
    pairwise mean comparisons. It is not identical to the full multivariate
    version but provides a practical diagnostic.{p_end}

{phang}
12. The MAR test uses logistic regression. If the regression does not converge
    (e.g., perfect prediction), that variable is reported as "Failed".{p_end}

{phang}
13. These tests cannot distinguish between MAR and MNAR. If the mechanism
    is classified as "possibly MNAR", consider domain-specific knowledge and
    running sensitivity analysis across multiple methods.{p_end}

{dlgtab:Graphs}

{phang}
14. All graphs are stored in memory with {opt nodraw}. Use
    {cmd:graph display} to view and {cmd:graph export} to save.{p_end}

{phang}
15. The density overlay (Graph 6) automatically generates an imputed version
    using linear interpolation if no {opt impvar()} is specified. To compare
    with a specific imputed variable, use {opt impvar(varname)}.{p_end}

{phang}
16. The pattern plot (Graph 5) is limited to datasets with <= 15 variables to
    avoid excessive pattern counts.{p_end}

{phang}
17. After modifying the .ado files, run {cmd:program drop _all} and
    {cmd:discard} to force Stata to reload the updated programs.{p_end}


{marker workflow}{...}
{title:Recommended Workflow}

{pstd}
The recommended workflow for handling missing data in panel data:{p_end}

{phang}
{bf:Step 1. Diagnose}{p_end}
{phang2}{cmd:. xtmispanel varlist, detect test}{p_end}
{phang2}Examine the four tables and mechanism test results.{p_end}

{phang}
{bf:Step 2. Visualize}{p_end}
{phang2}{cmd:. xtmispanel varlist, graph}{p_end}
{phang2}{cmd:. graph display xtmis_combined}{p_end}
{phang2}Check the heatmap and time trend for patterns.{p_end}

{phang}
{bf:Step 3. Compare methods}{p_end}
{phang2}{cmd:. xtmispanel varname, sensitivity}{p_end}
{phang2}See which method minimizes distributional distortion.{p_end}

{phang}
{bf:Step 4. Impute}{p_end}
{phang2}{cmd:. xtmispanel varname, impute(recommended_method)}{p_end}
{phang2}The imputed variable is added to the dataset.{p_end}

{phang}
{bf:Step 5. Validate}{p_end}
{phang2}{cmd:. xtmispanel varlist, graph impvar(varname_imp)}{p_end}
{phang2}{cmd:. graph display xtmis_density}{p_end}
{phang2}Compare original vs imputed distributions.{p_end}

{phang}
{bf:Step 6. Save}{p_end}
{phang2}{cmd:. save mydata_complete.dta, replace}{p_end}
{phang2}Save the dataset with imputed variables for analysis.{p_end}


{marker examples}{...}
{title:Examples}

{phang}{bf:Setup}{p_end}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

    {hline 60}
{phang}{bf:Example 1: Basic detection (default)}{p_end}

{phang2}{cmd:. xtmispanel ln_wage age hours tenure}{p_end}

{pstd}
When no option is given, {opt detect} is assumed. Displays four tables
summarizing missing data by variable, panel, time period, and pattern.{p_end}

    {hline 60}
{phang}{bf:Example 2: Detection with explicit detect option}{p_end}

{phang2}{cmd:. xtmispanel ln_wage age hours tenure, detect}{p_end}

    {hline 60}
{phang}{bf:Example 3: Mechanism testing only}{p_end}

{phang2}{cmd:. xtmispanel ln_wage age hours tenure, test}{p_end}

{pstd}
Runs Little's MCAR test, logistic MAR tests, and pattern classification.
Results stored in r(mechanism), r(mcar_chi2), r(mcar_pval).{p_end}

    {hline 60}
{phang}{bf:Example 4: Detect and test together}{p_end}

{phang2}{cmd:. xtmispanel ln_wage age hours, detect test}{p_end}

{pstd}
Produces all four tables plus all three tests in one call.{p_end}

    {hline 60}
{phang}{bf:Example 5: Impute using linear interpolation (default name)}{p_end}

{phang2}{cmd:. xtmispanel tenure, impute(linear)}{p_end}

{pstd}
Creates {bf:tenure_imp} in the dataset. Original {bf:tenure} is unchanged.{p_end}

    {hline 60}
{phang}{bf:Example 6: Impute with a custom variable name}{p_end}

{phang2}{cmd:. xtmispanel tenure, impute(mice) generate(tenure_mice) mice(10)}{p_end}

{pstd}
Creates {bf:tenure_mice} using MICE with 10 imputations.{p_end}

    {hline 60}
{phang}{bf:Example 7: Impute using KNN with 7 neighbors}{p_end}

{phang2}{cmd:. xtmispanel hours, impute(knn) knn(7)}{p_end}

{pstd}
Creates {bf:hours_imp} using 7 nearest time-neighbors within each panel.{p_end}

    {hline 60}
{phang}{bf:Example 8: Overwrite a previous imputation}{p_end}

{phang2}{cmd:. xtmispanel tenure, impute(linear)}{break}
{cmd:. xtmispanel tenure, impute(pmm) replace}{p_end}

{pstd}
First creates tenure_imp (linear), then replaces it with PMM results.{p_end}

    {hline 60}
{phang}{bf:Example 9: Sensitivity analysis (all 13 methods)}{p_end}

{phang2}{cmd:. xtmispanel tenure, sensitivity}{p_end}

{pstd}
Runs all 13 methods and displays a comparison table. The recommended method
(lowest mean distortion) is shown at the bottom and stored in r(best_method).{p_end}

    {hline 60}
{phang}{bf:Example 10: Sensitivity with specific methods}{p_end}

{phang2}{cmd:. xtmispanel tenure, sensitivity methods(mean linear pmm mice knn em)}{p_end}

{pstd}
Only compares the 6 specified methods.{p_end}

    {hline 60}
{phang}{bf:Example 11: Generate all diagnostic graphs}{p_end}

{phang2}{cmd:. xtmispanel ln_wage age hours tenure, graph}{p_end}
{phang2}{cmd:. graph display xtmis_combined}{p_end}

{pstd}
Creates 8 graphs. The density overlay auto-imputes the first variable.{p_end}

    {hline 60}
{phang}{bf:Example 12: Graphs with explicit imputed variable for density}{p_end}

{phang2}{cmd:. xtmispanel tenure, impute(linear)}{p_end}
{phang2}{cmd:. xtmispanel ln_wage age hours tenure, graph impvar(tenure_imp)}{p_end}
{phang2}{cmd:. graph display xtmis_density}{p_end}

{pstd}
The density overlay compares observed ln_wage vs the specified tenure_imp.{p_end}

    {hline 60}
{phang}{bf:Example 13: Export graphs as PNG}{p_end}

{phang2}{cmd:. xtmispanel ln_wage hours, graph}{p_end}
{phang2}{cmd:. graph export dashboard.png, name(xtmis_combined) replace width(1200)}{p_end}

    {hline 60}
{phang}{bf:Example 14: Full best-practice workflow}{p_end}

{phang2}{cmd:. * Step 1: Diagnose}{p_end}
{phang2}{cmd:. xtmispanel tenure, detect test}{p_end}
{phang2}{cmd:. * Step 2: Compare methods}{p_end}
{phang2}{cmd:. xtmispanel tenure, sensitivity}{p_end}
{phang2}{cmd:. * Step 3: Impute with recommended method}{p_end}
{phang2}{cmd:. xtmispanel tenure, impute(linear)}{p_end}
{phang2}{cmd:. * Step 4: Validate}{p_end}
{phang2}{cmd:. xtmispanel ln_wage tenure, graph impvar(tenure_imp)}{p_end}
{phang2}{cmd:. graph display xtmis_density}{p_end}
{phang2}{cmd:. * Step 5: Save}{p_end}
{phang2}{cmd:. save mydata_complete.dta, replace}{p_end}

    {hline 60}
{phang}{bf:Example 15: Using stored results programmatically}{p_end}

{phang2}{cmd:. xtmispanel tenure, impute(linear)}{p_end}
{phang2}{cmd:. local nfill = r(n_imputed)}{p_end}
{phang2}{cmd:. local method = r(method)}{p_end}
{phang2}{cmd:. display "Filled `nfill' values using `method'"}{p_end}

{phang2}{cmd:. xtmispanel tenure, test}{p_end}
{phang2}{cmd:. if "`r(mechanism)'" == "MAR" {c -(}}{p_end}
{phang2}{cmd:.     xtmispanel tenure, impute(mice) replace}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

    {hline 60}
{phang}{bf:Example 16: Using if/in restrictions}{p_end}

{phang2}{cmd:. xtmispanel tenure if year >= 2000, detect}{p_end}
{phang2}{cmd:. xtmispanel tenure in 1/100, impute(mean)}{p_end}

    {hline 60}
{phang}{bf:Example 17: All numeric variables (no varlist)}{p_end}

{phang2}{cmd:. xtmispanel, detect}{p_end}

{pstd}
Analyzes all numeric variables excluding the panel and time identifiers.{p_end}


{marker faq}{...}
{title:Frequently Asked Questions}

{phang}
{bf:Q1: Does imputation modify my original variable?}{p_end}
{phang2}No. The original variable is never modified. A new variable
  (default: {it:varname_imp}) is added to your dataset.{p_end}

{phang}
{bf:Q2: Is the imputed variable saved automatically?}{p_end}
{phang2}It is added to the dataset in memory but NOT saved to disk until
  you explicitly run {cmd:save}.{p_end}

{phang}
{bf:Q3: Which method should I use?}{p_end}
{phang2}Run {cmd:xtmispanel varname, sensitivity} to compare all methods.
  The command will recommend the one with least distributional distortion.
  Also consider the mechanism (use {cmd:test} first).{p_end}

{phang}
{bf:Q4: Can I impute multiple variables at once?}{p_end}
{phang2}No. Imputation works on one variable at a time. Run the command
  separately for each variable:{p_end}
{phang2}{cmd:. xtmispanel var1, impute(linear)}{p_end}
{phang2}{cmd:. xtmispanel var2, impute(mice) generate(var2_mice)}{p_end}

{phang}
{bf:Q5: Why does sensitivity show "FAILED" for a method?}{p_end}
{phang2}Some methods (e.g., regression-based) may fail if there are too few
  observations or insufficient variation. The method is skipped and marked
  as FAILED.{p_end}

{phang}
{bf:Q6: What does the MCAR test p-value mean?}{p_end}
{phang2}p >= 0.05: fail to reject MCAR (missing is likely random).{break}
  p < 0.05: reject MCAR (missing depends on observed data = MAR/MNAR).{p_end}

{phang}
{bf:Q7: Can I use this with time series only (not panel)?}{p_end}
{phang2}No. This command is designed for panel data. For pure time series,
  use Stata's {cmd:ipolate} or {cmd:mi impute}.{p_end}

{phang}
{bf:Q8: Why does LOCF leave some values missing?}{p_end}
{phang2}LOCF cannot fill the first observation if it starts as missing
  (there is no previous value to carry forward). Use {bf:linear} or
  {bf:nocb} instead for complete imputation.{p_end}

{phang}
{bf:Q9: How do I reload updated .ado files?}{p_end}
{phang2}{cmd:program drop _all}{break}
  {cmd:discard}{p_end}

{phang}
{bf:Q10: Does this package require external dependencies?}{p_end}
{phang2}No. All methods are implemented using base Stata commands. No
  additional packages (ssc install) are needed.{p_end}


{marker references}{...}
{title:References}

{phang}
Little, R.J.A. 1988. A test of missing completely at random for multivariate
data with missing values. {it:Journal of the American Statistical Association}
83(404): 1198-1202.
{p_end}

{phang}
Rubin, D.B. 1987. {it:Multiple Imputation for Nonresponse in Surveys}.
New York: Wiley.
{p_end}

{phang}
van Buuren, S. and K. Groothuis-Oudshoorn. 2011. mice: Multivariate
Imputation by Chained Equations in R. {it:Journal of Statistical Software}
45(3): 1-67.
{p_end}

{phang}
Honaker, J. and G. King. 2010. What to do about missing values in
time-series cross-section data. {it:American Journal of Political Science}
54(2): 561-581.
{p_end}

{phang}
Schafer, J.L. 1997. {it:Analysis of Incomplete Multivariate Data}.
London: Chapman & Hall.
{p_end}

{phang}
Azur, M.J., E.A. Stuart, C. Frangakis, and P.J. Leaf. 2011. Multiple
imputation by chained equations: What is it and how does it work?
{it:International Journal of Methods in Psychiatric Research} 20(1): 40-49.
{p_end}

{phang}
Stekhoven, D.J. and P. Buhlmann. 2012. MissForest: non-parametric missing
value imputation for mixed-type data. {it:Bioinformatics} 28(1): 112-118.
{p_end}

{phang}
Troyanskaya, O. et al. 2001. Missing value estimation methods for DNA
microarrays. {it:Bioinformatics} 17(6): 520-525.
{p_end}

{phang}
Dempster, A.P., N.M. Laird, and D.B. Rubin. 1977. Maximum likelihood from
incomplete data via the EM algorithm. {it:Journal of the Royal Statistical
Society, Series B} 39(1): 1-38.
{p_end}

{phang}
Allison, P.D. 2001. {it:Missing Data}. Sage University Papers Series on
Quantitative Applications in the Social Sciences, 07-136. Thousand Oaks, CA: Sage.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite as:{break}
Roudane, M. (2026). xtmispanel: Comprehensive Missing Data Detection,
Imputation and Diagnostics for Panel Data. Statistical Software Components,
Boston College Department of Economics.{p_end}
{smcl}
