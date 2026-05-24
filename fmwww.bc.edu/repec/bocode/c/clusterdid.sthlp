{smcl}
{cmd:help clusterdid}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:clusterdid} {hline 2}}Power analysis for cluster randomized trials, difference-in-differences sample size, and repeated cross-sections power calculator. Determines minimum detectable effect size (MDES), required clusters, and sample scale for dynamic panel evaluations.{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 11 2}{cmd:clusterdid} [{cmd:,} {it:evaluation_targets} {it:design_options}]

{pstd}
You must specify exactly {bf:three} of the four {it:evaluation_targets} ({opt m}, {opt n}, {opt d}/({opt p}), or {opt power}). The command will automatically evaluate the missing parameter. Providing a {it:numlist} for any single target automatically generates a diagnostic frontier graph.

{synoptset 24 tabbed}{...}
{synopthdr:Evaluation Targets}
{synoptline}
{synopt :{opt m(numlist)}}total number of level-2 clusters across both arms{p_end}
{synopt :{opt n(numlist)}}number of level-1 observations per cluster, per time period{p_end}
{synopt :{opt d(numlist)}}raw continuous mean difference (e.g., {cmd:d(15)}), or expected treatment and control means (e.g., {cmd:d(60 45)}){p_end}
{synopt :{opt p(numlist)}}expected treatment and baseline/control proportions for binary outcomes (e.g., {cmd:p(0.6 0.4)}). Replaces {opt d}{p_end}
{synopt :{opt power(numlist)}}statistical power (1 - beta){p_end}

{synopthdr:Design Options}
{synoptline}
{syntab:Architecture}
{synopt :{opt t0(#)}}number of baseline (pre-treatment) periods; default is {cmd:t0(1)}{p_end}
{synopt :{opt t1(#)}}number of evaluation (post-treatment) periods; default is {cmd:t1(1)}{p_end}
{synopt :{opt alloc(#)}}proportion of clusters assigned to treatment; default is {cmd:alloc(0.5)}{p_end}

{syntab:Error Components}
{synopt :{opt rhoj(#)}}between-cluster intraclass correlation coefficient (ICC); default is {cmd:rhoj(0.05)}{p_end}
{synopt :{opt rhot(#)}}time autocorrelation of the cluster-level error; default is {cmd:rhot(0.70)}{p_end}

{syntab:Covariate Adjustments}
{synopt :{opt r2c(#)}}proportion of cluster-level variance explained by covariates (partial R-squared); default is {cmd:r2c(0.0)}{p_end}
{synopt :{opt r2i(#)}}proportion of individual-level variance explained by covariates (partial R-squared); default is {cmd:r2i(0.0)}{p_end}

{syntab:Outcome Distributions}
{synopt :{opt sd(numlist)}}raw population standard deviation for continuous outcomes. Can accept a single value (e.g., {cmd:sd(15)}) or two values to be pooled (e.g., {cmd:sd(15 12)}); default is {cmd:sd(1.0)}{p_end}

{syntab:Significance}
{synopt :{opt alpha(#)}}Type I error probability (significance level); default is {cmd:alpha(0.05)}{p_end}

{syntab:Graphing}
{synopt :{opt name(string)}}name of the graph tab in Stata's memory (useful for keeping multiple graphs open simultaneously){p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:clusterdid} establishes a generalized, parallel-group difference-in-differences (DiD) cluster randomized trial framework observed over a longitudinal panel of T = T0 + T1 periods. It integrates the multi-way and nested error component models from Baltagi (2021) to capture permanent and time-varying cluster shocks.

{pstd}
Unlike legacy power commands restricted to single post-treatment snapshots or purely standardized metrics, {cmd:clusterdid} natively accommodates multi-period repeated cross-sections, allowing researchers to evaluate how expanding baseline and endline tracking horizons mathematically reduces the variance multiplier. 

{pstd}
{bf:Precision Gains & Covariate Adjustments:} Unlike older tools that apply a blunt, global correlation penalty across all variance, {cmd:clusterdid} properly partitions covariate adjustment. Users can specify {opt r2c} to absorb cluster-level shocks (e.g., school district funding) and {opt r2i} to absorb idiosyncratic individual-level shocks (e.g., student baseline test scores). This mathematically isolates the variance reduction to the correct tier in the error components framework.

{pstd}
The command operates seamlessly across outcome types using an intuitive 1- or 2-value input parser:
{break}{bf:1. Continuous Outcomes:} Users can specify a single raw difference ({cmd:d(15)}) or paired treatment and control means ({cmd:d(60 45)}). Standard deviations can likewise be specified as a single population parameter ({cmd:sd(20)}) or paired values to be pooled ({cmd:sd(20 18)}). If {opt sd} is omitted, it defaults to 1.0 (standardized effect size).
{break}{bf:2. Binary Proportions:} By specifying {opt p}, users can provide paired expected treatment and control proportions ({cmd:p(0.6 0.4)}) or a single treatment target ({cmd:p(0.6)}, which implicitly assumes a 0.5 baseline). The command automatically routes inputs through a linear probability model approximation, imputing the binomial population variance without requiring manual standardization.

{pstd}
{bf:Automated Graphing Engine:} Supplying a Stata {it:numlist} to any evaluation target (e.g., {cmd:m(10(5)50)}) triggers an automated line graph mapping the evaluation parameter frontier. If standard policy benchmarks (e.g., 80% power) are intercepted, the graph automatically overlays target crosshairs and intersection points. Using the {opt name} option allows users to pop open multiple scenarios in separate tabs for easy comparison.


{title:Examples}

{pstd}{bf:1. Classic 2x2 DiD with continuous outcome (Solving for Power)}{p_end}
{phang2}Solve for statistical power given 1 pre-period, 1 post-period, 40 total clusters, 50 individuals per cluster, paired treatment and control means of 60 and 45, and a pooled standard deviation of 45:{p_end}
{phang2}{cmd:. clusterdid, t0(1) t1(1) rhoj(0.05) rhot(0.70) m(40) n(50) d(60 45) sd(45)}

{pstd}{bf:2. Symmetric Multi-Period Panel with Binary Proportion (Solving for Clusters)}{p_end}
{phang2}Determine required total clusters for a 3-baseline, 3-endline panel tracking an employment intervention moving from 40% (control) to 50% (treatment):{p_end}
{phang2}{cmd:. clusterdid, t0(3) t1(3) rhoj(0.05) rhot(0.70) p(0.50 0.40) n(30) power(0.80)}

{pstd}{bf:3. Asymmetric Reality (Solving for MDE with imbalanced allocation)}{p_end}
{phang2}Determine the expected raw mean difference required for a trial with 1 baseline, 4 endlines, a 30/70 treatment allocation split, and unequal standard deviations (1.2 and 1.5):{p_end}
{phang2}{cmd:. clusterdid, t0(1) t1(4) alloc(0.30) rhoj(0.10) rhot(0.50) m(60) n(20) power(0.80) sd(1.2 1.5)}

{pstd}{bf:4. Covariate-Adjusted Power Evaluation}{p_end}
{phang2}Calculate the required sample scale (n) when incorporating covariates that explain 40% of the cluster-level variance and 15% of the individual-level variance:{p_end}
{phang2}{cmd:. clusterdid, t0(2) t1(2) rhoj(0.08) rhot(0.60) r2c(0.40) r2i(0.15) m(30) d(0.20) power(0.80)}

{pstd}{bf:5. Generating an Interactive Graph (Range Plotting with Tabs)}{p_end}
{phang2}Visualize the power curve across a range of cluster counts from 10 to 80, given a raw difference of 0.25 and an SD of 1.0. Name the graph so it opens in a new tab without overwriting your existing ones:{p_end}
{phang2}{cmd:. clusterdid, t0(2) t1(2) rhoj(0.05) rhot(0.70) m(10(2)80) n(50) d(0.25) sd(1.0) name(power_curve, replace)}


{title:Saved results}

{pstd}
{cmd:clusterdid} saves the following scalars in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(m)}}Total number of level-2 clusters{p_end}
{synopt:{cmd:r(mt)}}Number of level-2 clusters in the treatment arm{p_end}
{synopt:{cmd:r(mc)}}Number of level-2 clusters in the control arm{p_end}
{synopt:{cmd:r(n)}}Number of level-1 observations per cluster, per period{p_end}
{synopt:{cmd:r(delta)}}Raw minimum detectable effect size (MDE){p_end}
{synopt:{cmd:r(power)}}Statistical power (1 - beta){p_end}
{synopt:{cmd:r(N)}}Total individual observations across all groups and all tracked periods{p_end}


{title:Author}

{pstd}Wael Moussa, PhD{p_end}
{pstd}FHI 360{p_end}
{pstd}Washington, DC{p_end}
{pstd}wmoussa@fhi360.org{p_end}


{title:References}

{pstd}Baltagi, B. H. (2021). Econometric Analysis of Panel Data. Springer Texts in Business and Economics.{p_end}

{pstd}Frison, L. and Pocock, S. J. (1992). Repeated measures in clinical trials: Analysis using mean summary statistics and its implications for design. Statistics in Medicine, 11(13):1685-1704.{p_end}

{pstd}McKenzie, D. (2012). Beyond baseline and follow-up: The case for more T in experiments. American Economic Journal: Applied Economics, 4(2):210-234.{p_end}

{pstd}Schochet, P. Z. (2021). Statistical Power for Estimating Treatment Effects Using Difference-in-Differences and Comparative Interrupted Time Series Estimators with Variation in Treatment Timing.{p_end}


{title:Disclaimer}

{pstd}Any errors are the author's alone. Please email wmoussa@fhi360.org to report any issues.{p_end}
{smcl}