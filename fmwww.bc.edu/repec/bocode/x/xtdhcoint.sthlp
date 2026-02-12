{smcl}
{* *! version 1.0.0  10feb2026}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{viewerjumpto "Syntax" "xtdhcoint##syntax"}{...}
{viewerjumpto "Description" "xtdhcoint##description"}{...}
{viewerjumpto "Options" "xtdhcoint##options"}{...}
{viewerjumpto "Remarks" "xtdhcoint##remarks"}{...}
{viewerjumpto "Examples" "xtdhcoint##examples"}{...}
{viewerjumpto "Stored results" "xtdhcoint##results"}{...}
{viewerjumpto "References" "xtdhcoint##references"}{...}
{viewerjumpto "Author" "xtdhcoint##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:xtdhcoint} {hline 2}}Durbin-Hausman panel cointegration tests{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtdhcoint}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt k:max(#)}}maximum number of common factors; default is 5{p_end}
{synopt:{opt c:riterion(string)}}information criterion for factor selection: 
    {opt ic}, {opt pc}, {opt aic}, or {opt bic}; default is {opt ic}{p_end}
{synopt:{opt p:enalty(#)}}penalty type (1, 2, or 3); default is 1{p_end}
{synopt:{opt pre:det(#)}}use predetermined cointegrating coefficient{p_end}
{synopt:{opt noc:onstant}}suppress constant term in regression{p_end}

{syntab:Inference}
{synopt:{opt b:andwidth(#)}}kernel bandwidth for HAC estimation; 
    default is Newey-West automatic{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt not:able}}suppress output table{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
A panel variable and a time variable must be specified using {helpb xtset}.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdhcoint} implements the Durbin-Hausman panel cointegration tests 
proposed by Westerlund (2008). These tests are designed to test the null 
hypothesis of no cointegration against the alternative of cointegration in
panel data settings.

{pstd}
The tests have several important advantages over existing panel cointegration
tests:

{p 8 12 2}
1. They allow for cross-sectional dependence through common factors.

{p 8 12 2}
2. They are robust to stationary regressors.

{p 8 12 2}
3. They can accommodate predetermined cointegrating vectors.

{p 8 12 2}
4. Their asymptotic distributions are standard normal.

{pstd}
Two test statistics are computed:

{p 8 12 2}
{bf:DHg} (group mean test): Tests H0: phi_i = 1 for all i versus 
H1: phi_i < 1 for some i. A rejection suggests cointegration for at 
least some cross-sectional units.

{p 8 12 2}
{bf:DHp} (panel test): Tests H0: phi_i = 1 for all i versus 
H1: phi_i = phi < 1 for all i. A rejection suggests cointegration for 
all cross-sectional units with a common autoregressive parameter.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt kmax(#)} specifies the maximum number of common factors to consider
when selecting the optimal number using information criteria. The default 
is 5. The actual number of factors used is selected by minimizing the 
specified information criterion.

{phang}
{opt criterion(string)} specifies the information criterion used to 
determine the number of common factors:

{p 12 16 2}
{opt ic} uses the IC_p1 criterion of Bai and Ng (2002). This is the default.

{p 12 16 2}
{opt pc} uses the PC_p1 criterion of Bai and Ng (2002).

{p 12 16 2}
{opt aic} uses the Akaike Information Criterion.

{p 12 16 2}
{opt bic} uses the Bayesian Information Criterion.

{phang}
{opt penalty(#)} specifies the penalty function type (1, 2, or 3) as 
described in Bai and Ng (2002). The default is 1.

{phang}
{opt predet(#)} specifies a predetermined value for the cointegrating 
coefficient. When specified, the test uses this value instead of 
estimating the coefficient from the data. This is useful for testing
specific theoretical restrictions, such as the unit coefficient in 
the Fisher effect. Default is 0 (estimate the coefficient).

{phang}
{opt noconstant} suppresses the constant term in the cointegrating regression.

{dlgtab:Inference}

{phang}
{opt bandwidth(#)} specifies the bandwidth for the Bartlett kernel 
used in heteroskedasticity and autocorrelation consistent (HAC) variance 
estimation. The default is the Newey-West automatic bandwidth:
floor(4*(T/100)^(2/9)).

{phang}
{opt level(#)} sets the confidence level for determining whether to reject 
the null hypothesis. The default is 95.

{dlgtab:Reporting}

{phang}
{opt notable} suppresses the display of the results table.


{marker remarks}{...}
{title:Remarks}

{pstd}
The Durbin-Hausman tests are based on comparing two estimators of the 
autoregressive parameter in the recumulated defactored residuals. Under 
the null hypothesis of no cointegration, both the OLS and IV estimators 
converge to unity. Under the alternative of cointegration, the OLS 
estimator remains consistent while the IV estimator does not, leading 
to a divergence that forms the basis of the test.

{pstd}
The test procedure involves the following steps:

{p 8 12 2}
1. Estimate the cointegrating regression in first differences.

{p 8 12 2}
2. Extract common factors from the residuals using principal components.

{p 8 12 2}
3. Defactor the residuals.

{p 8 12 2}
4. Recumulate the defactored residuals.

{p 8 12 2}
5. Compute the Durbin-Hausman statistics using OLS and IV estimators.

{p 8 12 2}
6. Standardize using the asymptotic moments from Westerlund (2008).

{pstd}
The simulated moments (100,000 replications, T=1000) are:

{p 8 8 2}
E(B_i) = 5.5464, Var(B_i) = 36.7673

{p 8 8 2}
E(C_i) = 0.5005, Var(C_i) = 0.3348

{pstd}
Both standardized statistics diverge to positive infinity under the 
alternative hypothesis, so the computed value should be compared to the 
right tail of the normal distribution.

{marker interpretation}{...}
{title:Interpreting the output}

{pstd}
The output table shows:

{p 8 12 2}
{bf:Avg.Stat}: The average per-unit statistic (raw sum divided by N). This 
is comparable across different sample sizes.

{p 8 12 2}
{bf:E(.) H0}: The theoretical mean of the average statistic under the null 
hypothesis of no cointegration. For DHg, E(B_i) = 5.5464. For DHp, 
1/E(C_i) = 1/0.5005 = 1.998.

{p 8 12 2}
{bf:Z-value}: The standardized test statistic: Z = sqrt(N) * (Avg.Stat - E(.)) / se.
If Avg.Stat is close to E(.) H0, the z-value is near zero and there is no 
evidence against H0. If Avg.Stat is much larger than E(.) H0, the z-value 
is large and positive, indicating cointegration.

{p 8 12 2}
{bf:P-value}: Right-tail probability from the standard normal distribution.

{pstd}
{bf:Important}: Compare {bf:Avg.Stat} to {bf:E(.) H0} to understand the result.
If Avg.Stat {c 126} E(.) H0, the test fails to reject (no cointegration).
If Avg.Stat >> E(.) H0, the test rejects (evidence of cointegration).

{pstd}
{bf:Note on multiple regressors}: The simulated moments are valid for K=1 
(one regressor). With multiple regressors, run separate bivariate tests.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Basic test for cointegration{p_end}
{phang2}{cmd:. xtdhcoint invest mvalue kstock}{p_end}

{pstd}Test with predetermined coefficient (e.g., testing Fisher effect with unit slope){p_end}
{phang2}{cmd:. xtdhcoint invest mvalue, predet(1)}{p_end}

{pstd}Specify maximum factors and criterion{p_end}
{phang2}{cmd:. xtdhcoint invest mvalue, kmax(3) criterion(bic)}{p_end}

{pstd}Access stored results{p_end}
{phang2}{cmd:. xtdhcoint invest mvalue kstock}{p_end}
{phang2}{cmd:. display "DHg z-value: " r(dhg_z)}{p_end}
{phang2}{cmd:. display "DHp p-value: " r(dhp_p)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtdhcoint} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of cross-sectional units{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(K)}}number of regressors{p_end}
{synopt:{cmd:r(nf)}}estimated number of common factors{p_end}
{synopt:{cmd:r(bandwidth)}}kernel bandwidth used{p_end}
{synopt:{cmd:r(kmax)}}maximum factors considered{p_end}
{synopt:{cmd:r(dhg)}}DHg raw statistic{p_end}
{synopt:{cmd:r(dhp)}}DHp raw statistic{p_end}
{synopt:{cmd:r(dhg_z)}}DHg standardized z-value{p_end}
{synopt:{cmd:r(dhp_z)}}DHp standardized z-value{p_end}
{synopt:{cmd:r(dhg_p)}}DHg asymptotic p-value{p_end}
{synopt:{cmd:r(dhp_p)}}DHp asymptotic p-value{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable names{p_end}
{synopt:{cmd:r(criterion)}}information criterion used{p_end}


{marker references}{...}
{title:References}

{phang}
Bai, J., and S. Ng. 2002. Determining the number of factors in approximate
factor models. {it:Econometrica} 70: 191-221.

{phang}
Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.

{phang}
Pedroni, P. 2004. Panel cointegration: Asymptotic and finite sample 
properties of pooled time series tests with an application to the PPP 
hypothesis. {it:Econometric Theory} 3: 579-625.

{phang}
Westerlund, J. 2008. Panel cointegration tests of the Fisher effect.
{it:Journal of Applied Econometrics} 23: 193-233.
{browse "https://doi.org/10.1002/jae.967"}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
merwanroudane920@gmail.com

{pstd}
Based on the original GAUSS code by Joakim Westerlund (Lund University).


{title:Also see}

{p 7 14 2}
Help:  {helpb xtunitroot}, {helpb xtcointtest}, {helpb dfgls}
{p_end}
