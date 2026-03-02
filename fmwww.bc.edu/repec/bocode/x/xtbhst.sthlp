{smcl}
{* 28feb2026}{...}
{cmd:help xtbhst} {right:version 1.0.0}
{hline}
{title:Title}

{p 4 4}{cmd:xtbhst} - bootstrap test for slope homogeneity in large panels. 

{title:Version}

{pstd}
Version 1.0.0, 28 February 2026

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{title:Syntax}

{p 4 13}{cmd:xtbhst} {depvar} {indepvars} [if] [in] , {cmd:reps(}{it:{help integer}}{cmd:)} [{cmd:blocklength(}{it:{help integer}}{cmd:)} {cmd:partial({help varlist:varlist_p})} 
{cmdab:noconst:ant} 
{cmd:seed(}{it:{help string}}{cmd:)}
{cmdab:cr:osssectional(}{help varlist:varlist_cr}
{cmd: [,cr_lags(}{help numlist}{cmd:)])}
{cmdab:gr:aph}
{cmdab:noout:put}
]{p_end}

{p 4 4}{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{break}
Data must be {cmd:xtset} before using {cmd:xtbhst}; see {help xtset}.
{p_end}

{p 4 4}{it:depvar} is the dependent variable of the model to be tested,
{it:indepvar} the independent variables.{break}
{it:varlist_p} are the variables to be partialled out, 
{it:varlist_cr} are variables added as cross-sectional averages.{p_end}

{title:Contents}

{p 4}{help xtbhst##options:Options}{p_end}
{p 4}{help xtbhst##description:Description}{p_end}
{p 4}{help xtbhst##econmetricmodel:Econometric Model}{p_end}
{p 4}{help xtbhst##saved_vales:Saved Values}{p_end}
{p 4}{help xtbhst##examples:Examples}{p_end}
{p 4}{help xtbhst##references:References}{p_end}
{p 4}{help xtbhst##about:About}{p_end}

{marker description}{title:Description}

{p 4 4} {cmd:xtbhst} performs a block bootstrap test of slope homogeneity in panels with 
a large number observations of the cross-sectional (N) and time (T) dimension. 
The null hypothesis of the test is of homogenous slopes. 
This implies all slope coefficients are identical across cross-sectional units.{p_end}

{p 4 4} The test is a block-bootstrapped version of Swamy's test for slope homogeneity, evaluated using the resampling scheme proposed by Blomquist and Westerlund (2015).
This procedure is asymptotically valid in the presence of serial correlation and cross-sectional dependence of unknown form.
Unlike standard homogeneity tests which impose asymptotic critical values, the bootstrap corrects for finite-sample size distortions
and accommodates complicated unobserved dependencies simply through block resampling.
{p_end}

{p 4 4} The procedure estimates a weighted fixed effects model and panel unit-specific OLS 
regressions, partialling out variables expected to be heterogeneous (like the constant or user-defined variables). 
Then, it resamples blocks of the estimated residuals (maintaining the cross-sectional structure) to compute 
empirical P-values. Large original test statistics diverging from the bootstrapped distribution indicate 
rejection of slope homogeneity.{p_end}

{p 4 4} {cmd:xtbhst} requires a {ul:strongly balanced panel} to perform the block-bootstrap appropriately. 
Like {cmd:xthst}, it also allows adding cross-sectional averages to the model.{p_end}

{p 4 4} Additionally, {cmd:xtbhst} introduces a powerful {opt graph} option that automatically renders a combined, 
publication-quality visual diagnostic grid. It plots the empirical bootstrap distributions of the 
(adjusted) Delta statistics alongside the entire cross-sectional density of the heterogeneous slope estimates.{p_end}


{marker econmetricmodel}{title:Econometric Model}

{p 4 4} Based on Pesaran and Yamagata (2008), consider the following model with k = k1 + k2 regressors{p_end}

{p 8 8} y_it = alpha_i + x1_it * beta1_i + x2_it * beta2_i + e_it {p_end}

{p 4 4} or {p_end}

{p 8 8} y_it = z1_it * theta_i + x2_it * beta2_i + e_it {p_end}

{p 4 4} where z1_it = (1, x1_it), theta_i = (alpha_i, beta1_i), 
x1_it contains k1 regressors and x2_it contains k2.
Suppose the coefficient of interest are those in {it:beta_i},
then the hypothesis of slope homogeneity is:{p_end} 

{p 8 12} H0: beta2_i = beta2, for all i = 1,...,N{p_end}

{p 4 4} The derived test statistic by Pesaran and Yamagata (2008) is:

{p 8 12} Delta = sqrt(N) ((1/N * S2_tilde - k_2)/sqrt(2*k_2)) {p_end}

{p 4 4} S2_tilde is defined as in equation 13 in Peasaran and Yamagata (2008):{p_end}

{p 8 12} S2_tilde = sum(i=1,N) (b2_i - b2_wfe)'((X2_i' * M1_i * X2_i)/sigma2_i)(b2_i - b2_wfe), {p_end}

{p 4 4} where b2_i is the estimate of beta2_i obtained from individual least squares regression, M1_i partials out the heterogeneous variables Z1_i,
and b2_wfe is the weighted fixed effects estimator. {p_end}

{p 4 4} To handle complex serial or cross-sectional dependencies, Blomquist and Westerlund (2015) construct pseudo-data
y_it* = z1_it * theta_i + x2_it * b2_wfe + e_it*, where e_it* is sampled with replacement in blocks of length l across the time dimension
for all N cross-sections simultaneously.
{cmd:xtbhst} then recomputes the Delta and adjusted Delta statistic for each bootstrap iteration b = 1...B. The empirical
one-sided p-value is the fraction of bootstrap iterations which result in a test statistic strictly greater than the original
value of Delta. {p_end}


{marker options}{title:Options}

{p 4 4}{cmd:reps(}{it:{help integer}}{cmd:)} specifies the number of bootstrap replications to perform. {ul:This option is required.}
{p_end}

{p 4 4}{cmd:blocklength(}{it:{help integer}}{cmd:)} specifies the block length parameter l for drawing residuals. If set to 1, this results in a standard random 
bootstrap. If not specified, the default is set following the data-driven rule l = floor(2 * T^(1/3)).{p_end}

{p 4 4}{cmdab:noconst:ant} suppresses the individual heterogeneous constant, alpha_i. {p_end}

{p 4 4}{cmd:partial(}{help varlist:varlist_p}{cmd:)} requests exogenous regressors in {it:varlist_p} to be partialled out.
The constant is automatically partialled out, if included in the model.
Regressors in {it:varlist} will be included in z_it, explained in {help xtbhst##econmetricmodel:Econometric Model}.
These regressors are assumed to have heterogeneous slopes.{p_end}

{p 4 4}{cmd:seed(}{it:{help string}}{cmd:)} allows users to set a random seed string to perfectly replicate the bootstrap draws.{p_end}

{p 4 4}{cmdab:cr:osssectional(}{help varlist:varlist_cr}{cmd: [,cr_lags(}{help numlist}{cmd:)])} 
defines the variables which are added as cross-sectional averages to the model to approximate cross-sectional dependence.
Variables in {it:varlist_cr} are partialled out.
{cmd:cr_lags}({help numlist}) sets the number of lags of the cross-sectional averages. 
If not defined, but {cmd:crosssectional()} contains a varlist, then only contemporaneous cross sectional averages are added but no lags. 
{cmd:cr_lags(0)} is the equivalent.{p_end}

{p 4 4}{cmdab:gr:aph} generates publication-quality visualization of the heterogeneity tests. It produces a combined multi-panel graph containing: 
1) The Bootstrap Distribution Plot of the bootstrapped $\Delta^*$ statistics. 
2) The Bootstrap Distribution Plot of the bootstrapped Adjusted $\Delta^*$ statistics.
3+) The Coefficient Heterogeneity Plots displaying the density of the individual slope estimates $\hat{\beta}_i$ against the pooled $\hat{\beta}_{WFE}$ estimate for each heterogeneous variable.{p_end}

{p 4 4}{cmdab:noout:put} omits output.  {p_end}

{marker graphs}{title:Diagnostics and Graphs}

{p 4 4}By simply appending the {opt graph} option to any command, {cmd:xtbhst} seamlessly constructs a publication-ready visual diagnostics dashboard.{p_end}

{p 4 4}The dashboard is rendered as a clean multi-panel grid contrasting the theoretical bounds against exact empirical distributions:{p_end}
{p 8 12 2}- {bf:Bootstrap Distributions}: Two panels charting the resampled densities of the Delta and Adjusted Delta test statistics (in transparent blue), contrasting directly against the observed values marked by bold dashed cutoffs.{p_end}
{p 8 12 2}- {bf:Slope Heterogeneity}: For every heterogeneous regressor evaluated, a dedicated sub-panel plots the exact density curves of the $N$ independently estimated unit-specific slope coefficients $\hat{\beta}_i$ (in transparent teal) against the pooled restricted fixed-effects baseline.{p_end}

{marker saved_vales}{title:Saved Values}

{cmd:xtbhst} stores the following in {cmd:r()}:

{col 4} Scalars
{col 8}{cmd: r(blocklength)}{col 27} selected block length parameter l
{col 8}{cmd: r(reps)}{col 27} number of bootstrap replications

{col 4} Macros
{col 8}{cmd: r(crosssectional)}{col 27} variables of which cross-section averages are added
{col 8}{cmd: r(partial)}{col 27} variables partialled out

{col 4} Matrices
{col 8}{cmd: r(delta)}{col 27} delta and adjusted delta test statistics
{col 8}{cmd: r(delta_p)}{col 27} empirical bootstrap p-values corresponding to the original delta


{marker examples}{title:Examples}

{p 4 4}An example dataset taken from the Penn World Tables 8 is used to test the slope homogeneity
in a balanced panel consisting of completely observed periods.{p_end}

{p 4 4}We want to test whether slope coefficients in a simple Solow-type growth 
model are homo- or heterogeneous. 
We draw B = 499 replications for the bootstrap approximation:{p_end}

{p 8}{stata xtbhst d.log_rgdpo log_hc log_ck log_ngd, reps(499)}.{p_end}

{p 4 4}To fix the seed to allow replicability, we use:{p_end}

{p 8}{stata xtbhst d.log_rgdpo log_hc log_ck log_ngd, reps(499) seed(123456)}.{p_end}

{p 4 4}To construct the exact 2x2 multi-panel layout detailed in the Diagnostics section, displaying the two Delta distributions alongside the slope densities for {it:mvalue} and {it:kstock}:{p_end}

{p 8}{stata xtbhst invest mvalue kstock, reps(499) seed(123456) graph}.{p_end}

{p 4 4}In case the assumption is that all variables except the lag of GDP are heterogeneous,
the {cmd:partial(}{help varlist:varlist_partial}{cmd:)} option can be used as in {cmd:xthst}:

{p 8}{stata xtbhst d.log_rgdpo L.d.log_rgdpo log_hc log_ck log_ngd, reps(499) partial(log_hc log_ck log_ngd)}.{p_end}


{marker references}{title:References}

{p 4 8} Blomquist, J. and J. Westerlund. 2015. Panel bootstrap tests of slope homogeneity.
Empirical Economics. {browse "https://doi.org/10.1007/s00181-015-0978-z":https://doi.org/10.1007/s00181-015-0978-z}{p_end}

{p 4 8} Pesaran, M. H. and T. Yamagata. 2008. Testing slope homogeneity in large panels.
Journal of Econometrics 142, pp 50 - 93.{p_end}

{title:Author}

{pstd}
Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{marker about}{title:About and Acknowledgements}
{p 4}This routine is a bootstrap extension of the {cmd:xthst} ado-file originally developed by Tore Bersvendsen and Jan Ditzen. We are grateful for their open-source contributions to panel econometrics in Stata.{p_end}
