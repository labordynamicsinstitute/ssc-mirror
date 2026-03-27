{smcl}
{* *! version 1.0.0  25mar2026}{...}
{viewerjumpto "Title" "xtlmbreak##title"}{...}
{viewerjumpto "Syntax" "xtlmbreak##syntax"}{...}
{viewerjumpto "Description" "xtlmbreak##description"}{...}
{viewerjumpto "Options" "xtlmbreak##options"}{...}
{viewerjumpto "Models" "xtlmbreak##models"}{...}
{viewerjumpto "Methodology" "xtlmbreak##methodology"}{...}
{viewerjumpto "Assumptions" "xtlmbreak##assumptions"}{...}
{viewerjumpto "Interpretation" "xtlmbreak##interpretation"}{...}
{viewerjumpto "Examples" "xtlmbreak##examples"}{...}
{viewerjumpto "Stored results" "xtlmbreak##stored"}{...}
{viewerjumpto "References" "xtlmbreak##references"}{...}
{viewerjumpto "Author" "xtlmbreak##author"}{...}

{marker title}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:xtlmbreak} {hline 2}}Panel LM cointegration test with multiple structural breaks{p_end}
{p2colreset}{...}

    {bf:Version:} 1.0.0
    {bf:Date:}    25 March 2026
    {bf:Author:}  Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtlmbreak}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(string)}}deterministic specification; default is {bf:intercept}{p_end}
{synopt:{opt esti:mator(string)}}estimation method: {bf:dols} or {bf:fmols}; default is {bf:dols}{p_end}

{syntab:Break detection}
{synopt:{opt maxb:reaks(#)}}maximum number of structural breaks; default is {bf:5}{p_end}
{synopt:{opt trim(#)}}trimming parameter; default is {bf:0.15}{p_end}
{synopt:{opt maxi:ter(#)}}maximum iterations for break estimation; default is {bf:50}{p_end}
{synopt:{opt tol:erance(#)}}convergence criterion; default is {bf:0.0001}{p_end}

{syntab:Output}
{synopt:{opt gr:aph}}display and export visualizations of break dates and LM statistics{p_end}
{synoptline}

{p 4 6 2}
A balanced panel dataset must be declared using {cmd:xtset} {it:panelvar} {it:timevar}
before using {cmd:xtlmbreak}; see {helpb xtset}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtlmbreak} implements the panel LM test for the null hypothesis of
cointegration proposed by {bf:Westerlund (2006)}, published in the
{it:Oxford Bulletin of Economics and Statistics}. The test extends the
McCoskey and Kao (1998) panel LM cointegration test to allow for
{bf:multiple structural breaks} in both the level and trend of the
cointegrated panel regression.

{pstd}
The command is a direct translation of the original GAUSS code
({bf:llm.src}) written by Joakim Westerlund.

{pstd}
The test is based on the LM principle and tests:

{p 8 8 2}
{bf:H0:} All individuals in the panel are cointegrated{break}
{bf:H1:} At least some individuals are not cointegrated

{pstd}
The test statistic has a limiting standard normal distribution under H0.
Structural breaks are allowed under {it:both} the null and alternative
hypotheses, which avoids the interpretational difficulties associated
with tests that only allow breaks under the alternative.

{pstd}
The test proceeds as follows:

{phang}1. For each panel unit, determine the number and locations of structural
breaks using the Bai and Perron (1998, 2003) dynamic programming algorithm
with BIC model selection. This step applies only to Cases 4 and 5.{p_end}

{phang}2. Estimate the cointegrating regression for each subsample using
either DOLS (Saikkonen, 1991) or FMOLS (Phillips and Hansen, 1990) to
obtain efficient residuals.{p_end}

{phang}3. Compute the individual LM statistics based on cumulative sums of
the efficient residuals, using a Fejér/Bartlett kernel estimate of the
long-run variance with bandwidth [T^(1/3)].{p_end}

{phang}4. Standardize the panel statistic using response surface moments
from Westerlund (2006, Tables 2 and 3), which provide finite-sample
corrected expected values and variances.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(string)} specifies the deterministic component of the
cointegrating regression. Options are:

{p 12 12 2}
{bf:none} (or {bf:1}) {hline 2} Case 1: no deterministic component{break}
{bf:intercept} (or {bf:2}) {hline 2} Case 2: individual-specific intercept [default]{break}
{bf:trend} (or {bf:3}) {hline 2} Case 3: individual intercept and trend{break}
{bf:levelbreak} (or {bf:4}) {hline 2} Case 4: intercept with level breaks{break}
{bf:trendbreak} (or {bf:5}) {hline 2} Case 5: intercept and trend with breaks{p_end}

{phang}
{opt estimator(string)} selects the efficient estimation method:
{bf:dols} (default) uses Dynamic OLS with [T^(1/3)] leads and lags;
{bf:fmols} uses Fully Modified OLS with Bartlett kernel bandwidth [T^(1/3)].

{dlgtab:Break detection}

{phang}
{opt maxbreaks(#)} sets the maximum number of structural breaks to
search for. The actual number is selected by BIC. Default is 5.

{phang}
{opt trim(#)} sets the trimming parameter epsilon, which imposes a
minimum subsample length of [epsilon*T]. Default is 0.15, following
Bai and Perron (2003).

{phang}
{opt maxiter(#)} maximum iterations for the Bai-Perron iterative
break estimation procedure. Default is 50.

{phang}
{opt tolerance(#)} convergence criterion for the iterative break
estimation. The algorithm stops when |SSR_new - SSR_old| < tolerance.
Default is 0.0001.

{dlgtab:Output}

{phang}
{opt graph} produces two visualizations when break models (Cases 4-5)
are used: (1) a timeline chart of estimated break dates by panel;
(2) a bar chart of individual LM statistics. Graphs are automatically
exported as {bf:xtlmbreak_breaks.png} and {bf:xtlmbreak_lm.png} in
the current working directory.

{marker models}{...}
{title:Deterministic specifications}

{pstd}
The data generating process is:

{p 8 8 2}
y_it = z_it' * c_ij + x_it' * b_i + e_it{break}
e_it = r_it + u_it{break}
r_it = r_{i,t-1} + phi_i * u_it

{pstd}
where x_it is a K-dimensional I(1) regressor, z_it contains deterministic
components, and the index j = 1,...,M_i+1 denotes regimes. Under H0,
phi_i = 0 for all i.

{p2colset 5 25 27 2}{...}
{p2col:Case}Deterministic specification{p_end}
{p2line}
{p2col:{bf:1 (none)}}    z_it = empty{p_end}
{p2col:{bf:2 (intercept)}}z_it = 1 (individual-specific intercept){p_end}
{p2col:{bf:3 (trend)}}    z_it = (1, t)' (intercept and trend){p_end}
{p2col:{bf:4 (levelbreak)}}z_it = 1, with M_i level breaks{p_end}
{p2col:{bf:5 (trendbreak)}}z_it = (1, t)', with M_i level and trend breaks{p_end}
{p2line}

{pstd}
Cases 1{hline 1}3 do not involve structural breaks (M_i = 0 for all i).
Cases 4{hline 1}5 allow multiple breaks with locations and number estimated
from the data using the Bai-Perron algorithm and BIC selection.

{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:Individual LM statistic:}

{pstd}
For each panel unit i in regime j with T_ij observations, the LM
statistic sums the squared partial sums of efficient residuals:

{p 8 8 2}
LM_ij = (1/T_ij^2) * omega_hat^(-2) * sum_t S_it^2

{pstd}
where S_it = sum_{k=T_{i,j-1}+1}^{t} e*_ik are partial sums of DOLS
or FMOLS residuals and omega_hat^2 is the long-run conditional variance
estimated with a Bartlett/Fejér kernel with bandwidth [T^(1/3)].

{pstd}
{bf:Panel statistic (Theorem 1):}

{pstd}
The individual LM statistics across regimes are summed and then
standardized using response surface moments Q (expected value) and
R (variance) from Westerlund (2006, Tables 2{hline 1}3):

{p 8 8 2}
Z(M) = sqrt(N) * [ (1/N) * sum_i LM_i - mu_bar ] / sqrt(R_bar)

{pstd}
where mu_bar = (1/N) * sum_i (M_i+1)*Q and
R_bar = (1/N) * sum_i (M_i+1)^2*R.

{pstd}
Under H0, Z(M) converges to a standard normal distribution as
N -> infinity. The test rejects H0 for large {bf:positive} values
of Z(M), using the right tail of the N(0,1) distribution.

{pstd}
{bf:Key property:} The limiting distribution depends on M_i (the number
of breaks) but is {it:invariant} to the break {it:locations}. The moments
Q and R are functions of the model case (1{hline 1}5), the number of
regressors K, the estimator (DOLS/FMOLS), and the sample size T.

{marker assumptions}{...}
{title:Assumptions and requirements}

{pstd}
{bf:Data requirements:}

{phang}{bf:1.} Panel data must be declared with {helpb xtset}.{p_end}
{phang}{bf:2.} The panel must be {bf:balanced} (same T for all units).{p_end}
{phang}{bf:3.} The dependent variable y and regressors x must be I(1).{p_end}
{phang}{bf:4.} At least one independent variable is required.{p_end}

{pstd}
{bf:Statistical assumptions (Westerlund, 2006):}

{phang}{bf:Cross-sectional independence}: Panel members are independent
(Assumption 1(i)). For dependent panels, consider combining with
cross-sectional demeaning or bootstrap procedures.{p_end}

{phang}{bf:Serial correlation}: General forms of within-unit serial
dependence are allowed (Assumption 1(ii)). The Bartlett kernel provides
a heteroskedasticity- and autocorrelation-consistent variance estimate.{p_end}

{phang}{bf:Endogeneity}: Regressors x may be endogenous. Both DOLS and
FMOLS yield consistent estimation under endogeneity.{p_end}

{phang}{bf:Break locations}: Breaks are modeled as fixed fractions of T
with consecutive breaks being asymptotically distinct (Assumption 2).{p_end}

{phang}{bf:Minimum sample}: For reliable finite-sample performance,
each subsample should contain at least 30 observations. Use
{opt trim(0.15)} (default) as recommended by Bai and Perron (2003).{p_end}

{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Reading the output:}

{phang}{bf:1.} A large {bf:positive} Z(M) provides evidence {bf:against}
cointegration.{p_end}

{phang}{bf:2.} Compare Z(M) with right-tail critical values of N(0,1):
{bf:1.282} (10%), {bf:1.645} (5%), {bf:2.326} (1%).{p_end}

{phang}{bf:3.} If Z(M) exceeds the critical value, reject H0 and
conclude that at least some panel members are not cointegrated.{p_end}

{phang}{bf:4.} If Z(M) does not exceed the critical value, fail to
reject H0: the panel is cointegrated (with the specified break
structure).{p_end}

{pstd}
{bf:Practical guidance:}

{phang}{it:Ignoring breaks leads to size distortions.}
If cointegration is rejected using Cases 1{hline 1}3, re-test with
Cases 4{hline 1}5. Omitted structural breaks inflate the LM statistic and
can cause spurious rejection of cointegration.{p_end}

{phang}{it:Overspecifying the break model reduces power.}
If the true DGP has no breaks, using Cases 4{hline 1}5 produces valid but
less powerful tests compared to Cases 2{hline 1}3.{p_end}

{phang}{it:Break dates are data-driven.}
Report the break dates from r(breaks) and interpret them as approximate
indicators of regime changes.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup: Simulated cointegrated panel}{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 1000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/100)}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. bysort id (t): gen x = sum(rnormal())}{p_end}
{phang2}{cmd:. gen y = 1 + x + rnormal()*0.5}{p_end}

{pstd}{bf:Example 1: Test with individual intercept (Case 2, default)}{p_end}
{phang2}{cmd:. xtlmbreak y x}{p_end}

{pstd}{bf:Example 2: Test with intercept and trend (Case 3)}{p_end}
{phang2}{cmd:. xtlmbreak y x, model(trend)}{p_end}

{pstd}{bf:Example 3: Level break model with FMOLS}{p_end}
{phang2}{cmd:. xtlmbreak y x, model(levelbreak) estimator(fmols)}{p_end}

{pstd}{bf:Example 4: Trend break model with visualization}{p_end}
{phang2}{cmd:. xtlmbreak y x, model(trendbreak) maxbreaks(3) graph}{p_end}

{pstd}{bf:Example 5: Accessing stored results}{p_end}
{phang2}{cmd:. xtlmbreak y x, model(levelbreak)}{p_end}
{phang2}{cmd:. di "Z(M) = " r(Z_M) ", p-value = " r(p_value)}{p_end}
{phang2}{cmd:. mat list r(breaks)}{p_end}

{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtlmbreak} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(Z_M)}}standardized panel Z(M) test statistic{p_end}
{synopt:{cmd:r(p_value)}}p-value from right tail of N(0,1){p_end}
{synopt:{cmd:r(mean_lm)}}average of individual LM statistics{p_end}
{synopt:{cmd:r(mu_bar)}}cross-sectional mean mu_bar{p_end}
{synopt:{cmd:r(R_bar)}}cross-sectional variance R_bar{p_end}
{synopt:{cmd:r(Q)}}response surface expected value Q{p_end}
{synopt:{cmd:r(R)}}response surface variance R{p_end}
{synopt:{cmd:r(N)}}number of panel units{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(K)}}number of regressors{p_end}
{synopt:{cmd:r(maxbreaks)}}maximum breaks specified{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(breaks)}}({it:maxbreaks}+1 x N) matrix: row 1 = number of
breaks per panel; rows 2+ = estimated break dates{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}deterministic model specification{p_end}
{synopt:{cmd:r(estimator)}}estimation method{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable names{p_end}

{marker references}{...}
{title:References}

{phang}
Bai, J. and P. Perron (1998). Estimating and testing linear models with
multiple structural changes.
{it:Econometrica} 66(1): 47{hline 1}78.
{browse "https://doi.org/10.2307/2998540"}
{p_end}

{phang}
Bai, J. and P. Perron (2003). Computation and analysis of multiple
structural change models.
{it:Journal of Applied Econometrics} 18(1): 1{hline 1}22.
{browse "https://doi.org/10.1002/jae.659"}
{p_end}

{phang}
Harris, D. and B. Inder (1994). A test of the null hypothesis of
cointegration. In Hargreaves C.P. (ed.),
{it:Nonstationary Time Series Analysis and Cointegration},
Oxford University Press, pp. 133{hline 1}152.
{p_end}

{phang}
McCoskey, S. and C. Kao (1998). A residual-based test of the null of
cointegration in panel data.
{it:Econometric Reviews} 17(1): 57{hline 1}84.
{browse "https://doi.org/10.1080/07474939808800403"}
{p_end}

{phang}
Phillips, P.C.B. and B.E. Hansen (1990). Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies} 57(1): 99{hline 1}125.
{browse "https://doi.org/10.2307/2297545"}
{p_end}

{phang}
Saikkonen, P. (1991). Asymptotically efficient estimation of
cointegration regressions.
{it:Econometric Theory} 7(1): 1{hline 1}21.
{browse "https://doi.org/10.1017/S0266466600004217"}
{p_end}

{phang}
Shin, Y. (1994). A residual-based test of the null of cointegration
against the alternative of no cointegration.
{it:Econometric Theory} 10(1): 91{hline 1}115.
{browse "https://doi.org/10.1017/S0266466600008240"}
{p_end}

{phang}
Westerlund, J. (2006). Testing for panel cointegration with multiple
structural breaks.
{it:Oxford Bulletin of Economics and Statistics} 68(1): 101{hline 1}132.
{browse "https://doi.org/10.1111/j.1468-0084.2006.00154.x"}
{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}

{pstd}
Based on original GAUSS code ({bf:llm.src}) by:{break}
Joakim Westerlund{break}
Department of Economics, Lund University
{p_end}

{pstd}
Please cite as:{break}
Roudane, M. (2026). {bf:xtlmbreak}: Panel LM cointegration test with
multiple structural breaks in Stata. Version 1.0.0.
{p_end}
