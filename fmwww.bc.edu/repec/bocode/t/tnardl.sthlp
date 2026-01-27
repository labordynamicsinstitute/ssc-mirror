{smcl}
{* *! version 1.00.00  24jan2026}{...}
{viewerjumpto "Syntax" "tnardl##syntax"}{...}
{viewerjumpto "Description" "tnardl##description"}{...}
{viewerjumpto "Options" "tnardl##options"}{...}
{viewerjumpto "Saved results" "tnardl##saved_results"}{...}
{viewerjumpto "Examples" "tnardl##examples"}{...}
{viewerjumpto "Author" "tnardl##author"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:tnardl} {hline 2}}Threshold Non-linear ARDL Estimator with Automatic Grid Search{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tnardl} {depvar} [{indepvars}] {ifin} {cmd:,} {opt target(varname)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model Specification}
{synopt :{opt target(varname)}}specify the threshold variable (required){p_end}
{synopt :{opt maxlags(#)}}set maximum number of lags for automatic selection; default is {cmd:2}{p_end}
{synopt :{opt trim(#)}}set trimming percentage for grid search (10-40); default is {cmd:15}{p_end}
{synopt :{opt crit:erion(string)}}model selection criterion: {cmd:aic} (default) or {cmd:bic}{p_end}

{syntab:Reporting}
{synopt :{opt nog:raph}}suppress stability (CUSUM) and dynamic multiplier graphs{p_end}
{synopt :{opt trim(#)}}widen search bounds if computation fails due to collinearity{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:tnardl} requires the {cmd:ardl} package to be installed ({stata "ssc install ardl":ssc install ardl}).


{marker description}{...}
{title:Description}

{pstd}
{cmd:tnardl} estimates a Three-Regime Threshold Non-linear Autoregressive Distributed Lag (TNARDL) model. 
Unlike standard NARDL models that assume a fixed threshold (usually zero), {cmd:tnardl} endogenously determines 
two optimal threshold values ({it:s1}, {it:s2}) using a grid search algorithm that minimizes the Residual Sum of Squares (RSS).

{pstd}
The command partitions the {opt target()} variable into three partial sum processes:
{p_end}
{phang2}1. {bf:Positive Regime}: Changes when the target variable is above the upper threshold ({it:s2}).{p_end}
{phang2}2. {bf:Medium Regime}: Changes when the target variable is between ({it:s1}) and ({it:s2}).{p_end}
{phang2}3. {bf:Negative Regime}: Changes when the target variable is below the lower threshold ({it:s1}).{p_end}

{pstd}
The command automatically performs:
{p_end}
{pmore}- Lag selection for the dependent and independent variables.{p_end}
{pmore}- Bounds testing for cointegration (Pesaran et al., 2001).{p_end}
{pmore}- Calculation of Long-Run Multipliers (Elasticities) with significance levels.{p_end}
{pmore}- Comprehensive Wald tests for Long-run, Short-run, and Joint asymmetry.{p_end}
{pmore}- Diagnostic tests (Serial Correlation, Heteroskedasticity, Normality, Functional Form).{p_end}
{pmore}- Plotting of CUSUM, CUSUMQ, and Dynamic Multiplier trajectories.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt target(varname)} is required. It specifies the variable used to determine the non-linear thresholds. 
The algorithm searches for structural breaks/thresholds within the distribution of the first difference of this variable.

{phang}
{opt maxlags(#)} specifies the maximum number of lags to be considered for the ARDL model. 
The optimal lag structure is chosen based on the specified information criterion. The default is 4 (suitable for annual/quarterly data).

{phang}
{opt trim(#)} specifies the trimming percentage for the grid search. It restricts the search for thresholds to the range 
[{it:trim}-th percentile, (100-{it:trim})-th percentile]. The default is 15 (searching between the 15th and 85th percentiles). 
{bf:Note:} If you encounter "Computation failed" or singular matrix errors, try increasing this value (e.g., {cmd:trim(25)}) to ensure enough observations fall into the medium regime.

{phang}
{opt criterion(string)} specifies the information criterion used to select the optimal lag length. 
It may be {cmd:aic} (Akaike Information Criterion) or {cmd:bic} (Bayesian Information Criterion). The default is {cmd:aic}.

{phang}
{opt nograph} suppresses the generation of the CUSUM, CUSUMQ, and Dynamic Multiplier graphs.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic usage with default settings}
{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. tnardl price weight length, target(mpg)}{p_end}

{pstd}
{bf:Example 2: Specifying lags and criterion}
{p_end}
{phang2}{cmd:. tnardl GDP Trade Openness, target(INF) maxlags(4) criterion(bic)}{p_end}

{pstd}
{bf:Example 3: Handling collinearity issues by widening the trimming parameter}
{p_end}
{phang2}{cmd:. tnardl GDP Invest, target(RER) trim(25)}{p_end}


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:tnardl} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(s1)}}Lower optimal threshold value{p_end}
{synopt:{cmd:e(s2)}}Upper optimal threshold value{p_end}
{synopt:{cmd:e(rss_min)}}Minimum Residual Sum of Squares achieved{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(asymmetry_tests)}}Matrix containing F-stats and P-values for Wald tests{p_end}
{synopt:{cmd:e(diag_results)}}Matrix containing diagnostic test statistics{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}Marks estimation sample{p_end}
{p2colreset}{...}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tnardl} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(s1)}}Lower optimal threshold value{p_end}
{synopt:{cmd:e(s2)}}Upper optimal threshold value{p_end}
{synopt:{cmd:e(rss_min)}}Minimum Residual Sum of Squares achieved{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tnardl}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}Coefficient vector{p_end}
{synopt:{cmd:e(V)}}Variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(sym_test)}}Matrix containing Wald test results for asymmetry{p_end}
{synopt:{cmd:e(diagnostics)}}Matrix containing diagnostic test statistics and p-values{p_end}

{pstd}
The command creates system variables ({it:target}_POS, {it:target}_MED, {it:target}_NEG) representing the partial sum processes based on the detected thresholds.{p_end}


{marker author}{...}
{title:Author}

{pstd}
{bf:Prof. Imadeddin A. Almosabbeh}{break}
Arab East Colleges, Saudi Arabia, Riyadh{break}
Email: msbbh68@hotmail.com, iaalmosabbeh@arabeast.edu.sa{break}

{pstd}
Please cite this command as:
{break}
Almosabbeh, I. A. (2026). TNARDL: Stata module to estimate Threshold Non-linear ARDL models.


{marker references}{...}
{title:References}

{phang}
Shin, Y., Yu, B., & Greenwood-Nimmo, M. (2014). Modelling Asymmetric Cointegration and Dynamic Multipliers in a Nonlinear ARDL Framework. 
{it:Festschrift in Honor of Peter Schmidt}, 281-314.

{phang}
Hansen, B. E. (1999). Threshold effects in non-dynamic panels: Estimation, testing, and inference. 
{it:Journal of Econometrics}, 93(2), 345-368.

{phang}
Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. 
{it:Journal of Applied Econometrics}, 16(3), 289-326.
{p_end}