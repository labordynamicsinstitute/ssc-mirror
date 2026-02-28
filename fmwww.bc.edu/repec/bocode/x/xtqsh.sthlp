{smcl}
{* *! version 1.0.0  27feb2026}{...}
{viewerjumpto "Syntax" "xtqsh##syntax"}{...}
{viewerjumpto "Description" "xtqsh##description"}{...}
{viewerjumpto "Options" "xtqsh##options"}{...}
{viewerjumpto "Methodology" "xtqsh##methodology"}{...}
{viewerjumpto "Saved results" "xtqsh##saved_results"}{...}
{viewerjumpto "Examples" "xtqsh##examples"}{...}
{viewerjumpto "Graphs" "xtqsh##graphs"}{...}
{viewerjumpto "References" "xtqsh##references"}{...}
{viewerjumpto "Author" "xtqsh##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:xtqsh} {hline 2}}Quantile Regression Slope Homogeneity Test for Panel Data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtqsh}
{depvar}
{indepvars}
{ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt tau(numlist)}}quantile(s) to test; values must be between 0 and 1{p_end}

{syntab:Variance estimation}
{synopt:{opt bw(method)}}bandwidth rule for kernel density estimation;
{it:method} is {bf:bofinger} or {bf:hallsheather} (default){p_end}
{synopt:{opt hac(#)}}number of HAC (Bartlett kernel) lags for serially
dependent data; default is 0 (i.i.d.){p_end}

{syntab:Test options}
{synopt:{opt mar:ginal}}perform additional marginal (per-variable) slope
homogeneity tests{p_end}
{synopt:{opt level(#)}}confidence level for bandwidth calculation;
default is {cmd:c(level)}{p_end}

{syntab:Reporting}
{synopt:{opt gr:aph}}produce visualization suite (5 graphs){p_end}
{synopt:{opt notable}}suppress tabular output{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
A panel variable and a time variable must be specified; use {helpb xtset}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqsh} implements the Swamy-type and standardized Swamy-type slope
homogeneity tests proposed by Galvao, Juhl, Montes-Rojas, and Olmo (2017)
for quantile regression (QR) fixed-effects panel data models.

{pstd}
The tests assess whether the slope coefficients in a panel QR model are
homogeneous across all cross-sectional units:

{p 8 12 2}
H₀ : β₁(τ) = β₂(τ) = ··· = βₙ(τ)  for a given quantile τ{p_end}
{p 8 12 2}
H₁ : βᵢ(τ) ≠ βⱼ(τ) for some i ≠ j{p_end}

{pstd}
{bf:Interpretation:} If the test does {it:not} reject H₀, pooling is
appropriate and one may use the standard FE-QR estimator. If the test
{it:rejects} H₀, slopes are heterogeneous and individual time-series
estimation for each panel is more appropriate.

{pstd}
{cmd:xtqsh} also reports the classical Swamy (1970) test applied to the
OLS (mean) regression as a baseline comparison.

{pstd}
{bf:Note:} At extreme quantiles (e.g., τ = 0.05 or 0.95) with small T,
Stata's built-in {cmd:qreg} may fail to estimate the sparsity function.
In such cases, {cmd:xtqsh} automatically falls back to a Mata-based IRLS
quantile regression solver to ensure valid estimates are produced.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt tau(numlist)} specifies one or more quantiles at which to perform the
slope homogeneity test. Multiple quantiles produce a table of results
across the distribution. Example: {cmd:tau(0.10 0.25 0.50 0.75 0.90)}.

{dlgtab:Variance estimation}

{phang}
{opt bw(method)} chooses the bandwidth rule for the Powell (1986) kernel
density estimator used in constructing the variance–covariance matrices.
{cmd:bofinger} uses the Bofinger (1975) rule; {cmd:hallsheather} (default)
uses the Hall–Sheather (1988) rule. These are the two rules studied in the
Monte Carlo experiments of Galvao et al. (2017).

{phang}
{opt hac(#)} activates the HAC adjustment for serially dependent data
(Theorem 2 of Galvao et al. 2017). When {it:#} > 0, a Newey–West style
Bartlett kernel with {it:#} lags is used to estimate the long-run variance
matrices. Use this when your data exhibit serial correlation (β-mixing).
A common rule of thumb is {it:#} = floor(T^{1/3}).

{dlgtab:Test options}

{phang}
{opt marginal} requests marginal (per-variable) slope homogeneity tests
in addition to the joint test. For each covariate individually, the
Swamy and standardized Swamy statistics are computed with k=1 and reported
in a separate table.

{phang}
{opt level(#)} sets the significance level used in the Hall–Sheather
bandwidth formula. Default is {cmd:c(level)}.

{dlgtab:Reporting}

{phang}
{opt graph} produces a suite of five publication-quality graphs: a p-value
process plot, a marginal p-value heatmap (if {opt marginal} is specified),
a coefficient distribution fan chart (replicating Figure 1 of the paper),
an MD-QR coefficient process with 95% CI bands, and a summary dashboard.

{phang}
{opt notable} suppresses all tabular output. Useful when only the stored
results or graphs are needed.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:Model.} Consider the fixed-effects panel QR model:

{p 8 12 2}
Q_{y_it}(τ | x_it, α_i) = α_i(τ) + x'_it β_i(τ)

{pstd}
where α_i(τ) are individual fixed effects and β_i(τ) are slope coefficients
that may differ across panels.

{pstd}
{bf:Step 1.} For each panel i, estimate the individual QR by demeaning:

{p 8 12 2}
β̂_i = argmin (1/T) Σ ρ_τ(ỹ_it − x̃'_it β)

{pstd}
{bf:Step 2.} Estimate the variance–covariance matrix of each β̂_i using the
Powell (1986) kernel density estimator for f_i(0|X):

{p 8 12 2}
V̂_i = τ(1−τ) Ĉ_i⁻¹ Ξ̂_i Ĉ_i⁻¹

{pstd}
{bf:Step 3.} Compute the Minimum Distance estimator:

{p 8 12 2}
β̂_MD = (Σ V̂_i⁻¹)⁻¹ Σ V̂_i⁻¹ β̂_i

{pstd}
{bf:Step 4.} The Swamy test statistic is:

{p 8 12 2}
Ŝ(τ) = Σ (β̂_i − β̂_MD)' (V̂_i/T)⁻¹ (β̂_i − β̂_MD) {break}
Ŝ → χ²_{(n−1)k} as T → ∞, n fixed

{pstd}
{bf:Step 5.} The standardized Swamy test statistic is:

{p 8 12 2}
D̂(τ) = √n × [(1/n)Ŝ − k] / √(2k) {break}
D̂ → N(0,1) as (T,n) → ∞


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:xtqsh} saves the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}total number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(k)}}number of covariates{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(valid_panels)}}number of panels with valid estimates{p_end}
{synopt:{cmd:e(S_ols)}}OLS (mean) Swamy statistic{p_end}
{synopt:{cmd:e(D_ols)}}OLS (mean) standardized Swamy statistic{p_end}
{synopt:{cmd:e(pval_S_ols)}}p-value of OLS Swamy test{p_end}
{synopt:{cmd:e(pval_D_ols)}}p-value of OLS standardized Swamy test{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(S)}}1 × ntau vector of Ŝ(τ) statistics{p_end}
{synopt:{cmd:e(D)}}1 × ntau vector of D̂(τ) statistics{p_end}
{synopt:{cmd:e(pval_S)}}1 × ntau vector of p-values for Ŝ{p_end}
{synopt:{cmd:e(pval_D)}}1 × ntau vector of p-values for D̂{p_end}
{synopt:{cmd:e(beta_md)}}ntau × k matrix of MD-QR coefficient estimates{p_end}
{synopt:{cmd:e(beta_md_se)}}ntau × k matrix of SE for MD-QR estimates{p_end}
{synopt:{cmd:e(beta_all)}}n × (k*ntau) matrix of individual β̂_i{p_end}
{synopt:{cmd:e(beta_ols)}}n × k matrix of individual OLS β̂_i{p_end}

{pstd}
If {opt marginal} is specified, additionally:

{synopt:{cmd:e(S_marginal)}}k × ntau matrix of marginal Ŝ statistics{p_end}
{synopt:{cmd:e(D_marginal)}}k × ntau matrix of marginal D̂ statistics{p_end}
{synopt:{cmd:e(pval_S_marginal)}}k × ntau matrix of marginal Ŝ p-values{p_end}
{synopt:{cmd:e(pval_D_marginal)}}k × ntau matrix of marginal D̂ p-values{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}xtqsh{p_end}
{synopt:{cmd:e(title)}}QR Slope Homogeneity Test (Galvao et al. 2017){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(tau)}}quantile values used{p_end}
{synopt:{cmd:e(bw)}}bandwidth method used{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Simulated data under H₀ (homogeneous slopes)}

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 10000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/100)}{p_end}
{phang2}{cmd:. gen t = mod(_n-1, 100) + 1}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. gen alpha_i = id/100}{p_end}
{phang2}{cmd:. gen x1 = 0.3*alpha_i + rnormal()}{p_end}
{phang2}{cmd:. gen x2 = rnormal()}{p_end}
{phang2}{cmd:. bysort id (t): gen y = alpha_i + 1.0*x1 + 0.5*x2 + rnormal()}{p_end}
{phang2}{cmd:. xtqsh y x1 x2, tau(0.10 0.25 0.50 0.75 0.90) graph}{p_end}

{pstd}
{bf:Example 2: With marginal tests and HAC}

{phang2}{cmd:. xtqsh y x1 x2, tau(0.05(0.05)0.95) marginal hac(3)}{p_end}

{pstd}
{bf:Example 3: Using Bofinger bandwidth}

{phang2}{cmd:. xtqsh y x1 x2, tau(0.25 0.50 0.75) bw(bofinger) graph}{p_end}


{marker graphs}{...}
{title:Graphs}

{pstd}
When {opt graph} is specified, {cmd:xtqsh} produces the following graphs:

{phang2}1. {bf:xtqsh_pvalue} — P-value process plot: p(Ŝ) and p(D̂) across
quantiles with horizontal significance lines at 1%, 5%, and 10%.{p_end}

{phang2}2. {bf:xtqsh_heatmap} — Marginal p-value heatmap (if {opt marginal}
specified): color-coded matrix of D̂ p-values by variable × quantile.{p_end}

{phang2}3. {bf:xtqsh_fan_combined} — Coefficient distribution fan chart:
percentiles (5th, 10th, 20th, 80th, 90th, 95th) of firm-specific β̂_i
across quantiles, overlaid with MD-QR and OLS estimates. This replicates
Figure 1 of Galvao et al. (2017).{p_end}

{phang2}4. {bf:xtqsh_mdqr_combined} — MD-QR coefficient process: β̂_MD(τ) with
95% confidence interval bands.{p_end}

{phang2}5. {bf:xtqsh_dashboard} — Summary dashboard combining key graphs.{p_end}


{marker references}{...}
{title:References}

{phang}
Galvao, A. F., T. Juhl, G. Montes-Rojas, and J. Olmo. 2017.
Testing Slope Homogeneity in Quantile Regression Panel Data with an
Application to the Cross-Section of Stock Returns.
{it:Journal of Financial Econometrics}, 1–33.
{p_end}

{phang}
Swamy, P. A. V. B. 1970. Efficient Inference in a Random Coefficient
Regression Model. {it:Econometrica} 38: 311–323.
{p_end}

{phang}
Pesaran, M. H. and T. Yamagata. 2008. Testing Slope Homogeneity in Large
Panels. {it:Journal of Econometrics} 142: 50–93.
{p_end}

{phang}
Koenker, R. and G. W. Bassett. 1978. Regression Quantiles.
{it:Econometrica} 46: 33–49.
{p_end}

{phang}
Galvao, A. F. and L. Wang. 2015. Efficient Minimum Distance Estimator for
Quantile Regression Fixed Effects Panel Data.
{it:Journal of Multivariate Analysis} 133: 1–26.
{p_end}

{phang}
Kato, K., A. F. Galvao, and G. Montes-Rojas. 2012. Asymptotics for Panel
Quantile Regression Models with Individual Effects.
{it:Journal of Econometrics} 170: 76–91.
{p_end}

{phang}
Bofinger, E. 1975. Estimation of a Density Function Using Order Statistics.
{it:Australian Journal of Statistics} 17: 1–7.
{p_end}

{phang}
Hall, P. and S. Sheather. 1988. On the Distribution of a Studentized
Quantile. {it:Journal of the Royal Statistical Society, Series B} 50: 381–391.
{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite this package as:{p_end}

{phang2}Roudane, M. (2026). xtqsh: Quantile Regression Slope Homogeneity Test
for Panel Data. Stata package version 1.0.0.{p_end}

{pstd}
When using {cmd:xtqsh}, please also cite the original theoretical paper:{p_end}

{phang2}Galvao, A. F., T. Juhl, G. Montes-Rojas, and J. Olmo (2017).
Testing Slope Homogeneity in Quantile Regression Panel Data with an
Application to the Cross-Section of Stock Returns.
{it:Journal of Financial Econometrics}, 1–33.{p_end}
{hline}
