{smcl}
{* *! version 1.0.0  08feb2026}{...}
{viewerjumpto "Syntax" "cointsmall##syntax"}{...}
{viewerjumpto "Description" "cointsmall##description"}{...}
{viewerjumpto "Options" "cointsmall##options"}{...}
{viewerjumpto "Examples" "cointsmall##examples"}{...}
{viewerjumpto "Stored results" "cointsmall##results"}{...}
{viewerjumpto "References" "cointsmall##references"}{...}
{viewerjumpto "Author" "cointsmall##author"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{cmd:cointsmall} {hline 2}}Testing for cointegration with structural breaks in very small samples{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cointsmall}
{depvar} {indepvars}
{ifin}
{cmd:,}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt b:reaks(#)}}number of structural breaks (0, 1, or 2); default is {cmd:breaks(1)}{p_end}
{synopt:{opt m:odel(string)}}model specification: {cmd:o} (no break), {cmd:c} (break in constant), 
or {cmd:cs} (break in constant and slope); default is {cmd:cs} if breaks > 0{p_end}
{synopt:{opt cri:terion(string)}}break date selection criterion: {cmd:adf} (minimize test statistic) 
or {cmd:ssr} (minimize sum of squared residuals); default is {cmd:adf}{p_end}

{syntab:Optional}
{synopt:{opt com:bined}}perform combined testing procedure across all model specifications{p_end}
{synopt:{opt tr:im(#)}}trimming parameter for break date search; default is {cmd:trim(0.15)}{p_end}
{synopt:{opt maxl:ags(#)}}maximum number of lags for ADF test; 
default is int(12*(T/100)^0.25){p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt det:ail}}display detailed regression output{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{it:depvar} and {it:indepvars} must be time series variables.{p_end}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:cointsmall}; see {helpb tsset}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointsmall} implements the cointegration test with endogenous structural breaks 
designed for very small sample sizes (T < 50) proposed by Trinh (2022). The test extends 
the Gregory and Hansen (1996) procedure to allow for up to two structural breaks and 
provides size-corrected critical values specifically computed for small samples.

{pstd}
The test is particularly useful for:

{phang2}• Analyzing macroeconomic data from emerging economies with limited data history{p_end}
{phang2}• Testing cointegration relationships with less than 50 annual observations{p_end}
{phang2}• Detecting structural breaks in long-run relationships{p_end}
{phang2}• Situations where conventional cointegration tests have size distortions{p_end}

{pstd}
The null hypothesis is no cointegration. The alternative hypothesis is cointegration 
with or without structural breaks in the parameters. The test statistic is the minimum 
ADF statistic (ADF*) computed over all possible break dates.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt breaks(#)} specifies the number of structural breaks to test for. Options are:

{phang2}
{cmd:breaks(0)} tests for cointegration without structural breaks (model o). 
This is equivalent to the Engle-Granger residual-based test but with size-corrected 
critical values for small samples.

{phang2}
{cmd:breaks(1)} tests for cointegration with one endogenous structural break. 
The break date is selected to minimize the ADF statistic (if {cmd:criterion(adf)}) 
or the sum of squared residuals (if {cmd:criterion(ssr)}).

{phang2}
{cmd:breaks(2)} tests for cointegration with two endogenous structural breaks. 
Both break dates are jointly selected using the specified criterion.

{phang}
{opt model(string)} specifies the type of structural break:

{phang2}
{cmd:model(o)} specifies no structural break. Only the constant is included in the 
cointegrating regression. This option is only compatible with {cmd:breaks(0)}.

{phang2}
{cmd:model(c)} specifies a structural break in the constant (intercept) only. 
The slope coefficients remain constant across regimes.

{phang2}
{cmd:model(cs)} specifies structural breaks in both the constant and slope coefficients. 
This is the most general specification and is the default when {cmd:breaks} > 0.

{phang}
{opt criterion(string)} specifies how break dates are selected:

{phang2}
{cmd:criterion(adf)} selects break date(s) that minimize the ADF test statistic. 
This is the default and follows Gregory and Hansen (1996).

{phang2}
{cmd:criterion(ssr)} selects break date(s) that minimize the sum of squared residuals. 
This follows Bai and Perron (1998) and focuses on model fit rather than test power.

{dlgtab:Optional}

{phang}
{opt combined} performs a combined testing procedure that:

{phang2}
1. Tests all three model specifications (o, c, cs){p_end}
{phang2}
2. Identifies which models reject the null hypothesis{p_end}
{phang2}
3. Selects the most appropriate model based on rejection patterns{p_end}

{pstd}
This option is recommended when the true model specification is unknown. 
It improves power by considering multiple alternatives while maintaining proper size.

{phang}
{opt trim(#)} specifies the trimming parameter for the break date search. 
Break dates are searched in the interval [trim*T, (1-trim)*T]. The default is 0.15, 
meaning break dates must be at least 15% from the start or end of the sample. 
This ensures sufficient observations in each regime for estimation.

{phang}
{opt maxlags(#)} specifies the maximum number of lags to consider in the ADF regression. 
The optimal lag length is selected using the Bayesian Information Criterion (BIC). 
The default is int(12*(T/100)^0.25), following Schwert (1989).

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for critical values. 
The default is {cmd:level(95)} for 5% significance level. 
Only 95% (5% level) is currently supported.

{phang}
{opt detail} displays detailed regression output including coefficient estimates 
and standard errors for the final selected model.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Basic test with one break, default options{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump}{p_end}

{pstd}Test with one break in constant only{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(1) model(c)}{p_end}

{pstd}Test with two breaks in constant and slope{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(2) model(cs)}{p_end}

{pstd}Test without structural breaks (Engle-Granger with size correction){p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(0)}{p_end}

{pstd}Combined testing procedure (recommended for unknown specification){p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(1) combined}{p_end}

{pstd}Use SSR criterion for break date selection{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(1) criterion(ssr)}{p_end}

{pstd}Show detailed regression output{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(1) detail}{p_end}

{pstd}Specify trimming and maximum lags{p_end}
{phang2}{cmd:. cointsmall dln_inv dln_inc dln_consump, breaks(1) trim(0.20) maxlags(4)}{p_end}


{title:Example with Chinese macroeconomic data (from Trinh 2022)}

{pstd}This example replicates the application in Trinh (2022) Section 7.{p_end}

{phang2}{cmd:. * Load Chinese macroeconomic data (1989-2019)}{p_end}
{phang2}{cmd:. use chinese_macro.dta, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}

{phang2}{cmd:. * Test cointegration with 1 break}{p_end}
{phang2}{cmd:. cointsmall log_gdp log_retail log_investment, breaks(1) model(cs)}{p_end}

{phang2}{cmd:. * Compare with 2 breaks}{p_end}
{phang2}{cmd:. cointsmall log_gdp log_retail log_investment, breaks(2) model(cs)}{p_end}

{phang2}{cmd:. * Use combined procedure}{p_end}
{phang2}{cmd:. cointsmall log_gdp log_retail log_investment, breaks(1) combined detail}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cointsmall} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(T)}}number of observations{p_end}
{synopt:{cmd:r(m)}}number of regressors{p_end}
{synopt:{cmd:r(breaks)}}number of structural breaks{p_end}
{synopt:{cmd:r(adf_stat)}}ADF* test statistic{p_end}
{synopt:{cmd:r(lags)}}number of lags selected{p_end}
{synopt:{cmd:r(cv)}}critical value at specified level{p_end}
{synopt:{cmd:r(pval)}}p-value (approximate){p_end}
{synopt:{cmd:r(ssr)}}sum of squared residuals{p_end}
{synopt:{cmd:r(break1)}}first break date (time variable value){p_end}
{synopt:{cmd:r(break2)}}second break date (if breaks=2){p_end}
{synopt:{cmd:r(break1_obs)}}first break observation number{p_end}
{synopt:{cmd:r(break2_obs)}}second break observation number (if breaks=2){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}model specification (o, c, or cs){p_end}
{synopt:{cmd:r(criterion)}}break selection criterion (adf or ssr){p_end}

{pstd}
When {cmd:combined} is specified, additional results are stored:

{synopt:{cmd:r(adf_o)}}ADF statistic for model o{p_end}
{synopt:{cmd:r(adf_c)}}ADF statistic for model c{p_end}
{synopt:{cmd:r(adf_cs)}}ADF statistic for model cs{p_end}
{synopt:{cmd:r(cv_o)}}critical value for model o{p_end}
{synopt:{cmd:r(cv_c)}}critical value for model c{p_end}
{synopt:{cmd:r(cv_cs)}}critical value for model cs{p_end}
{synopt:{cmd:r(reject_o)}}1 if model o rejects null, 0 otherwise{p_end}
{synopt:{cmd:r(reject_c)}}1 if model c rejects null, 0 otherwise{p_end}
{synopt:{cmd:r(reject_cs)}}1 if model cs rejects null, 0 otherwise{p_end}
{synopt:{cmd:r(selected_model)}}selected model from combined procedure{p_end}


{marker technical}{...}
{title:Technical notes}

{pstd}
{bf:Sample size considerations:}

{pstd}
The test is designed for very small samples (T < 50) where conventional cointegration 
tests suffer from severe size distortions. The power of the test varies with:

{phang2}• Sample size: Power increases with T{p_end}
{phang2}• Serial correlation: Lower serial correlation improves power{p_end}
{phang2}• Model specification: Correct specification is crucial{p_end}
{phang2}• Break magnitude: Larger breaks are easier to detect{p_end}

{pstd}
From simulation evidence in Trinh (2022):

{phang2}• For T ≥ 30 and low serial correlation (ρ < 0.4): Power > 75%{p_end}
{phang2}• For T = 30 with model o: Power ≈ 90%{p_end}
{phang2}• For T = 30 with model cs: Power ≈ 60-70%{p_end}

{pstd}
{bf:Critical values:}

{pstd}
Size-corrected critical values are computed using surface response functions 
estimated from 10,000 Monte Carlo replications for each sample size. The critical 
values account for the high rate of convergence of residual-based cointegration tests.

{pstd}
Critical values are available for:

{phang2}• Sample sizes: T = 12 to 1,000{p_end}
{phang2}• Number of regressors: m = 1, 2, 3{p_end}
{phang2}• Number of breaks: b = 0, 1, 2{p_end}
{phang2}• Models: o, c, cs{p_end}

{pstd}
{bf:Break date selection:}

{pstd}
The ADF criterion (default) selects break dates to maximize the evidence against 
the null hypothesis. This approach has better power properties than the SSR criterion, 
particularly in small samples.

{pstd}
The SSR criterion focuses on model fit and may select different break dates. 
It tends to be more conservative (less likely to reject the null).

{pstd}
{bf:Combined testing procedure:}

{pstd}
The combined procedure tests all model specifications and uses a model selection 
algorithm based on:

{phang2}1. Which models reject the null hypothesis{p_end}
{phang2}2. Wald tests for parameter restrictions when multiple models reject{p_end}
{phang2}3. Parsimony principle when specifications are nested{p_end}

{pstd}
This approach improves power while maintaining proper size, especially when the 
true model specification is unknown.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
The test statistic for b structural breaks is:

{phang2}
ADF* = inf{t1,...,tb} ADF(ε̂)

{pstd}
where ε̂ are the residuals from:

{phang2}
Y = μ + X'β + Σ[i=1 to b] Di(μi + X'βi) + ε

{pstd}
and Di is a dummy variable equal to 1 for t ≥ ti.

{pstd}
The ADF test on residuals is:

{phang2}
Δε̂t = γε̂t-1 + Σ[j=1 to p] δjΔε̂t-j + ut

{pstd}
The test statistic is the t-statistic on γ. The optimal lag length p is selected 
using the BIC criterion.

{pstd}
Critical values are computed using surface response functions:

{phang2}
CV(T,q,m,b,M) = ψ∞ + Σ[k=1 to K] ψk T^(-k)

{pstd}
where coefficients are estimated from Monte Carlo simulations.


{marker references}{...}
{title:References}

{phang}
Trinh, J. 2022. Testing for cointegration with structural changes in very small sample. 
{it:THEMA Working Paper} n°2022-01, CY Cergy Paris Université.

{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in 
models with regime shifts. {it:Journal of Econometrics} 70: 99-126.

{phang}
Hatemi-j, A. 2008. Tests for cointegration with two unknown regime shifts with an 
application to financial market integration. {it:Empirical Economics} 35: 497-505.

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Co-integration and error correction: 
Representation, estimation, and testing. {it:Econometrica} 55: 251-276.

{phang}
Bai, J., and P. Perron. 1998. Estimating and testing linear models with multiple 
structural changes. {it:Econometrica} 66: 47-78.

{phang}
MacKinnon, J. G. 1991. Critical values for cointegration tests. In 
{it:Long-Run Economic Relationships: Readings in Cointegration}, ed. R. F. Engle and 
C. W. J. Granger, 267-276. Oxford: Oxford University Press.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: merwanroudane920@gmail.com


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
This package implements the methodology developed by Jérôme Trinh in his 2022 
working paper. The author thanks Professor Jérôme Trinh for making the research 
publicly available.


{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb dfuller}, {helpb pperron}, {helpb vec}, {helpb tsset}
{p_end}
