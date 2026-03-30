{smcl}
{* *! version 1.0.0  29mar2026}{...}
{cmd:help xtbreakmodel} {right:version 1.0.0}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{hi:xtbreakmodel} {hline 2}}Heterogeneous Structural Breaks in Panel Data Models{p_end}
{p2colreset}{...}


{title:Version}

{pstd}
Version 1.0.0, 29 March 2026{p_end}

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}){p_end}

{pstd}
Implements four state-of-the-art panel structural break estimators: GAGFL
(Okui and Wang, 2021), AGFL (Qian and Su, 2016), BFK (Baltagi, Feng and Kao,
2016), and SaRa (Li, Xiao and Chen, 2025).{p_end}


{title:Syntax}

{p 8 16 2}{cmd:xtbreakmodel} {depvar} {indepvars} {ifin}
{cmd:,} {opt m:ethod(string)} [{it:options}]{p_end}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt m:ethod(string)}}estimation method: {cmd:gagfl}, {cmd:pls}, {cmd:bfk}, or {cmd:sara} (required){p_end}
{synopt:{opt gr:oups(#)}}number of latent groups; required for {cmd:method(gagfl)}, minimum 2{p_end}

{syntab:GAGFL/PLS tuning}
{synopt:{opt maxl:ambda(#)}}upper bound of lambda grid; default is {cmd:maxlambda(100)}{p_end}
{synopt:{opt minl:ambda(#)}}lower bound of lambda grid; default is {cmd:minlambda(0.01)}{p_end}
{synopt:{opt ngr:id(#)}}number of log-spaced grid points; default is {cmd:ngrid(40)}{p_end}
{synopt:{opt nsim(#)}}number of random starts for GFE initialization; default is {cmd:nsim(50)}{p_end}
{synopt:{opt maxi:ter(#)}}maximum GAGFL iterations; default is {cmd:maxiter(20)}{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance; default is {cmd:tolerance(1e-4)}{p_end}

{syntab:SaRa tuning}
{synopt:{opt ban:dwidths(numlist)}}bandwidth values for local estimation; default is {cmd:bandwidths(3 5 8)}{p_end}
{synopt:{opt c1(#)}}IC penalty constant for static SaRa; default is {cmd:c1(0.1)}{p_end}
{synopt:{opt c2(#)}}IC penalty constant for dynamic SaRa; default is {cmd:c2(0.025)}{p_end}

{syntab:Reporting}
{synopt:{opt nogr:aph}}suppress coefficient path graphs{p_end}
{synopt:{opt l:evel(#)}}confidence level for CI bands; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtbreakmodel}; see {helpb xtset}.{p_end}
{p 4 6 2}
The panel must be {bf:strongly balanced} (no gaps or missing values).{p_end}
{p 4 6 2}
All four methods support {bf:one or more regressors} (K >= 1).{p_end}


{title:Description}

{pstd}
{cmd:xtbreakmodel} estimates structural breaks in panel data regression models
of the form:{p_end}

{p 8 12 2}y_it = x'_it * beta(t) + alpha_i + epsilon_it,   i = 1,...,N,  t = 1,...,T{p_end}

{pstd}
where alpha_i are individual fixed effects and beta(t) is a K-dimensional
coefficient vector that is piecewise constant over time with unknown break
dates. The command offers four different estimation methods, each with
different assumptions about the heterogeneity structure:{p_end}


{pstd}
{bf:Method 1: GAGFL — Grouped Adaptive Group Fused Lasso}{p_end}

{pstd}
Okui and Wang (2021, {it:Journal of Econometrics}). The most general method.
Allows units to belong to G latent groups, where each group has its own
break dates and regime-specific coefficients. Simultaneously estimates group
membership and group-specific structural breaks via an iterative algorithm
that alternates between Adaptive Group Fused Lasso (AGFL) estimation within
groups and unit reassignment across groups.{p_end}


{pstd}
{bf:Method 2: PLS — Adaptive Group Fused Lasso (Common Breaks)}{p_end}

{pstd}
Qian and Su (2016, {it:Journal of Econometrics}). Assumes all units share the
same break dates but coefficients may change at those dates. All K coefficients
are assumed to break simultaneously (vector break). The method uses Block
Coordinate Descent (BCD) with adaptive fused L1 penalty to determine breaks
and select the optimal tuning parameter via BIC-type information criterion.{p_end}


{pstd}
{bf:Method 3: BFK — Sequential Least Squares}{p_end}

{pstd}
Baltagi, Feng and Kao (2016). Detects common breaks via sequential least
squares minimization. For each candidate break date, the pooled SSR is
computed; the date minimizing total SSR is selected. Breaks are detected
sequentially: after finding the first break, the algorithm searches the
larger remaining segment for the next break.{p_end}


{pstd}
{bf:Method 4: SaRa — Screening and Ranking Algorithm}{p_end}

{pstd}
Li, Xiao and Chen (2025). Uses local kernel estimation of left and right
regression coefficients at each time point. The local statistic measuring
the difference between left and right estimates is computed at multiple
bandwidths. Break candidates are identified as local maximizers of this
statistic, filtered by a median threshold, and the final number is selected
via BIC-type information criterion.{p_end}


{title:Assumptions}

{pstd}
{bf:Common assumptions (all methods):}{p_end}

{p 8 12 2}(A1) {bf:Balanced panel:} The panel must be strongly balanced with no gaps
or missing observations within units.{p_end}

{p 8 12 2}(A2) {bf:Fixed effects:} Individual-specific intercepts alpha_i are
eliminated via within-group demeaning or first-period deviation.{p_end}

{p 8 12 2}(A3) {bf:Exogeneity:} E(epsilon_it | x_it, alpha_i) = 0 for static
panels. For dynamic specifications, appropriate instruments are required.{p_end}

{p 8 12 2}(A4) {bf:Regularity:} The regressors x_it must have sufficient within-period
variation: E(x_it * x'_it) is positive definite for each t.{p_end}

{p 8 12 2}(A5) {bf:Minimum segment length:} Each regime must contain at least
one time period. In practice, T >= 3 is required.{p_end}


{pstd}
{bf:Method-specific assumptions:}{p_end}

{p 8 12 2}{bf:GAGFL:} (i) The number of latent groups G is finite and known or
estimated separately (e.g., via BIC over a range of G). (ii) Group
membership is time-invariant: unit i belongs to group g_i for all t.
(iii) N -> infinity asymptotics with T fixed.{p_end}

{p 8 12 2}{bf:PLS:} (i) All N units share the same break dates
(common break assumption). (ii) Under Qian and Su (2016), the initial
estimator is sqrt(N)-consistent for each t, which requires N to be
large relative to T. (iii) The adaptive weight exponent kappa = 2 provides
oracle efficiency.{p_end}

{p 8 12 2}{bf:BFK:} (i) Common breaks across units. (ii) The sequential
procedure assumes the true number of breaks is bounded. (iii) The method
is robust to heteroskedasticity in the cross-section via pooled SSR
minimization.{p_end}

{p 8 12 2}{bf:SaRa:} (i) Common breaks. (ii) The bandwidths must be chosen
such that h << T^(1/2). (iii) The local kernel estimator requires sufficient
observations in each window (Nh > K). (iv) The method is non-parametric and
robust to distributional assumptions on the errors.{p_end}


{title:Requirements}

{pstd}
{bf:Software:} Stata 14.0 or higher. No external packages required.{p_end}

{pstd}
{bf:Data:}{p_end}

{p 8 12 2}(i)   {bf:Minimum dimensions:} N >= 10, T >= 3.{p_end}
{p 8 12 2}(ii)  {bf:Panel structure:} Must be {cmd:xtset} with both panel and time variables.{p_end}
{p 8 12 2}(iii) {bf:No gaps:} Strongly balanced panel; use {helpb tsfill} if needed.{p_end}
{p 8 12 2}(iv)  {bf:Non-collinearity:} Regressors must not be perfectly collinear.{p_end}
{p 8 12 2}(v)   {bf:GAGFL:} For G groups, N must be sufficiently large that each group
has at least 2 units. Rule of thumb: N >= 5*G.{p_end}
{p 8 12 2}(vi)  {bf:SaRa:} T must be large enough to support local estimation: T >= 2*max(bandwidth) + 1.{p_end}


{title:Options}

{dlgtab:Model specification}

{phang}
{opt method(string)} specifies the estimation method. One of:{p_end}

{p 8 12 2}{cmd:gagfl} — Grouped AGFL: heterogeneous breaks + latent groups (Okui and Wang, 2021){p_end}
{p 8 12 2}{cmd:pls} — AGFL: common breaks across all units (Qian and Su, 2016){p_end}
{p 8 12 2}{cmd:bfk} — Sequential least squares (Baltagi, Feng and Kao, 2016){p_end}
{p 8 12 2}{cmd:sara} — Screening and ranking algorithm (Li, Xiao and Chen, 2025){p_end}

{phang}
{opt groups(#)} specifies the number of latent groups G. Required when
{cmd:method(gagfl)} is specified. Must be >= 2. The choice of G can be guided
by the BIC criterion: estimate for G = 2, 3, 4, ... and choose the G that
minimizes BIC = SSR/(NT) + sigma^2 * (np_G + N) * ln(NT) / (NT).{p_end}


{dlgtab:GAGFL/PLS tuning}

{phang}
{opt maxlambda(#)} upper bound of the penalty parameter grid. Default is 100.
Increase if the algorithm selects the boundary lambda.{p_end}

{phang}
{opt minlambda(#)} lower bound of the penalty parameter grid. Default is 0.01.
Decrease for finer break detection (risks over-segmentation).{p_end}

{phang}
{opt ngrid(#)} number of log-spaced grid points between minlambda and maxlambda.
Default is 40. Higher values improve lambda selection precision but increase
computation time proportionally.{p_end}

{phang}
{opt nsim(#)} number of random initializations for the GFE step. Default
is 50. Higher values reduce sensitivity to initial conditions but increase
computation. The MATLAB reference uses 100.{p_end}

{phang}
{opt maxiter(#)} maximum number of GAGFL outer iterations (alternating between
group-specific AGFL and group reassignment). Default is 20. The algorithm
terminates earlier if the group assignment stabilizes.{p_end}

{phang}
{opt tolerance(#)} convergence threshold for the BCD solver. Default is 1e-4.
Smaller values give more precise estimates but take longer.{p_end}


{dlgtab:SaRa tuning}

{phang}
{opt bandwidths(numlist)} specifies the bandwidth(s) for local estimation.
Default is {cmd:bandwidths(3 5 8)}. Larger bandwidths smooth more and detect
only large breaks; smaller bandwidths detect finer breaks but are noisier.
Multiple bandwidths are recommended for robustness: candidates from all
bandwidths are pooled and filtered.{p_end}

{phang}
{opt c1(#)} IC penalty constant for break number selection in static SaRa.
Default is 0.1. Larger values are more conservative (fewer breaks).{p_end}


{dlgtab:Reporting}

{phang}
{opt nograph} suppresses the coefficient path graphs. By default,
{cmd:xtbreakmodel} produces regime-specific coefficient plots with confidence
bands and vertical dashed lines at estimated break dates.{p_end}

{phang}
{opt level(#)} specifies the confidence level for confidence intervals in
tables and graphs. Default is {cmd:level(95)}.{p_end}


{title:Methodology}

{pstd}
{bf:1. Data Generating Process}{p_end}

{pstd}
Consider the panel model:{p_end}

{p 8 12 2}y_it = alpha_i + x'_it * beta_{g_i}(t) + epsilon_it{p_end}

{pstd}
where g_i in {c -(}1,...,G{c )-} denotes unit i's group. Within group g,
the coefficient beta_g(t) is piecewise constant:{p_end}

{p 8 12 2}beta_g(t) = a_{g,j}  for  tau_{g,j-1} < t <= tau_{g,j},  j = 1,...,m_g+1{p_end}

{pstd}
with m_g breaks at dates tau_{g,1} < ... < tau_{g,m_g}.{p_end}

{pstd}
When G = 1, this reduces to the common-break model of Qian and Su (2016).{p_end}


{pstd}
{bf:2. GAGFL Algorithm (Okui and Wang, 2021)}{p_end}

{pstd}
The GAGFL estimator consists of three stages:{p_end}

{p 8 12 2}{bf:Stage 1 — Grouped Fixed Effects (GFE) initialization:} Following
Bonhomme and Manresa (2015), units are assigned to G groups via iterative
k-means clustering on time-varying coefficients. For each time t and unit i,
an initial beta_t is estimated by cross-sectional OLS. Multiple random starts
(nsim) are used to avoid local minima.{p_end}

{p 8 12 2}{bf:Stage 2 — Group-specific AGFL:} For each group g, the Adaptive
Group Fused Lasso is applied to the group's pooled data. This uses Block
Coordinate Descent (BCD) to solve:{p_end}

{p 12 16 2}minimize  (1/Ng) * SUM_i SUM_t [y_it - x'_it * beta_t]^2
+ lambda * SUM_{t=2}^T w_t * ||beta_t - beta_{t-1}||{p_end}

{p 8 12 2}where w_t = ||beta_dot_t - beta_dot_{t-1}||^(-2) are adaptive weights
computed from initial estimates, and ||.|| is the L2 norm (group lasso).
The penalty lambda is selected by minimizing a BIC-type IC over a grid.{p_end}

{p 8 12 2}{bf:Stage 3 — Group reassignment:} Units are reassigned to the group
whose estimated coefficient path minimizes the individual's residual sum of
squares. Stages 2-3 alternate until convergence.{p_end}


{pstd}
{bf:3. BCD Inner Solver (mirrors plsbcd.m / cplsbcd.c)}{p_end}

{pstd}
The BCD algorithm iteratively updates beta_t for t = 1,...,T. For t >= 2, the
update uses soft-thresholding combined with scalar optimization:{p_end}

{p 8 12 2}d_t = argmin  (1/2) * d' * A_t * d + g'_t * d + lambda * w_{t-1} * ||d||{p_end}

{pstd}
where A_t = SUM_{s>=t} X'_s X_s / N and g_t combines the gradient. If
||g_t|| <= lambda * w_{t-1}, the solution is d_t = 0 (fusing with previous
period). Otherwise, a line search with Brent's method determines the optimal
step size gamma*, giving d_t = -gamma* * (gamma* A_t + (lambda w_{t-1})^2/2 * I)^(-1) * g_t.{p_end}


{pstd}
{bf:4. BFK Sequential Detection (Baltagi, Feng and Kao, 2016)}{p_end}

{pstd}
For each candidate break date k in {c -(}1,...,T-1{c )-}, the pooled SSR is:{p_end}

{p 8 12 2}SSR(k) = SUM_{i=1}^N [SSR_i(1:k) + SSR_i(k+1:T)]{p_end}

{pstd}
where SSR_i(t1:t2) is the residual sum of squares from OLS of y_i on
(x_i, z_i) where z_i captures the regime indicator. The first break is
khat_1 = argmin SSR(k). Subsequent breaks are found by searching within
the largest remaining segment, sequentially subdividing.{p_end}


{pstd}
{bf:5. SaRa Algorithm (Li, Xiao and Chen, 2025)}{p_end}

{pstd}
For each bandwidth h and time t, the local statistic is:{p_end}

{p 8 12 2}Ds(t,h) = max_k |sqrt(N) * (beta_R_{k}(t,h) - beta_L_{k}(t,h))|{p_end}

{pstd}
where beta_L and beta_R are local OLS estimates from the left window
(t-h, t] and right window (t, t+h]. Break candidates are h-local maximizers
of Ds(t,h) across all bandwidths. These are filtered by a median threshold
and the final number is selected by BIC.{p_end}


{pstd}
{bf:6. Post-Estimation (all methods)}{p_end}

{pstd}
After break detection, regime-specific coefficients are re-estimated by
restricted OLS. For each regime j (from tau_{j-1}+1 to tau_j):{p_end}

{p 8 12 2}alpha_j = [SUM_i SUM_{t in regime_j} x_it x'_it]^(-1) * [SUM_i SUM_{t in regime_j} x_it y_it]{p_end}

{pstd}
Standard errors use the Eicker-Huber-White sandwich estimator:{p_end}

{p 8 12 2}V(alpha_j) = Phi^(-1) * Omega_j * Phi^(-1) / (N * tau_j){p_end}

{pstd}
where Phi = E(x x') and Omega_j = E(x x' * epsilon^2) in regime j.{p_end}


{title:Output Tables}

{pstd}
{cmd:xtbreakmodel} produces publication-quality output tables:{p_end}

{p 8 12 2}1. {bf:Header:} Model specifications, panel dimensions, method-specific
settings.{p_end}

{p 8 12 2}2. {bf:Break detection:} Number of breaks detected, break dates. For
GAGFL, this is reported per group.{p_end}

{p 8 12 2}3. {bf:Group membership (GAGFL only):} Number of units and breaks
per group.{p_end}

{p 8 12 2}4. {bf:Coefficient table:} Regime-specific estimates with standard
errors, z-statistics, p-values, and significance stars (* p<0.10,
** p<0.05, *** p<0.01). Each regressor is shown with its regime
interval.{p_end}

{p 8 12 2}5. {bf:Graphs:} Coefficient paths with confidence bands and vertical
dashed lines at break dates. GAGFL produces one panel per group,
combined into a single figure.{p_end}


{title:Stored Results}

{pstd}
{cmd:xtbreakmodel} stores the following in {cmd:e()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of cross-sectional units{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(p)}}number of regressors{p_end}
{synopt:{cmd:e(G)}}number of groups (1 for non-GAGFL methods){p_end}
{synopt:{cmd:e(ssr)}}total residual sum of squares{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(niter)}}number of iterations (GAGFL only){p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(nbreaks)}}1 x G vector of break counts per group{p_end}
{synopt:{cmd:e(regime)}}(max_regimes) x G matrix of regime start points{p_end}
{synopt:{cmd:e(alpha)}}(max_regimes) x (K*G) matrix of regime-specific coefficients{p_end}
{synopt:{cmd:e(se)}}(max_regimes) x (K*G) matrix of standard errors{p_end}
{synopt:{cmd:e(group)}}N x G group membership indicator matrix (GAGFL only){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtbreakmodel}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvars)}}independent variable names{p_end}
{synopt:{cmd:e(method)}}estimation method used{p_end}
{synopt:{cmd:e(title)}}estimation title{p_end}


{title:Examples}

{pstd}
{bf:Example 1: Basic PLS — Common breaks with single regressor}{p_end}

{phang}{cmd:. webuse grunfeld, clear}{p_end}
{phang}{cmd:. xtbreakmodel invest mvalue, method(pls)}{p_end}

{pstd}
Detects common structural breaks in the investment-market value relationship
across all firms. Uses default lambda grid [0.01, 100] with 40 grid points.{p_end}


{pstd}
{bf:Example 2: PLS with multiple regressors}{p_end}

{phang}{cmd:. webuse grunfeld, clear}{p_end}
{phang}{cmd:. xtbreakmodel invest mvalue kstock, method(pls) nograph}{p_end}

{pstd}
Estimates common breaks where both market value and capital stock coefficients
shift simultaneously (vector break assumption).{p_end}


{pstd}
{bf:Example 3: GAGFL — Heterogeneous breaks with latent groups}{p_end}

{phang}{cmd:. webuse grunfeld, clear}{p_end}
{phang}{cmd:. xtbreakmodel invest mvalue, method(gagfl) groups(2)}{p_end}

{pstd}
Classifies firms into 2 latent groups and estimates group-specific break
dates. This captures heterogeneity: e.g., some firms may have experienced
structural shifts in their investment behavior at different times.{p_end}


{pstd}
{bf:Example 4: BFK — Sequential break detection}{p_end}

{phang}{cmd:. webuse grunfeld, clear}{p_end}
{phang}{cmd:. xtbreakmodel invest mvalue kstock, method(bfk) nograph}{p_end}

{pstd}
Finds up to 3 breaks sequentially via SSR minimization. Simple and fast.{p_end}


{pstd}
{bf:Example 5: SaRa — Nonparametric screening}{p_end}

{phang}{cmd:. webuse grunfeld, clear}{p_end}
{phang}{cmd:. xtbreakmodel invest mvalue, method(sara) bandwidths(2 3 4) c1(0.1)}{p_end}

{pstd}
Screening and ranking with bandwidths 2, 3, 4. Robust to distributional
assumptions. The c1 parameter controls the BIC penalty for number of breaks.{p_end}


{pstd}
{bf:Example 6: Simulated DGP with known breaks}{p_end}

{phang}{cmd:. clear all}{p_end}
{phang}{cmd:. set seed 12345}{p_end}
{phang}{cmd:. local N = 100}{p_end}
{phang}{cmd:. local T = 20}{p_end}
{phang}{cmd:. set obs `=`N'*`T''}{p_end}
{phang}{cmd:. gen id = ceil(_n/`T')}{p_end}
{phang}{cmd:. bysort id: gen time = _n}{p_end}
{phang}{cmd:. xtset id time}{p_end}
{phang}{cmd:. gen x = rnormal()}{p_end}
{phang}{cmd:. gen group0 = cond(id <= 33, 1, cond(id <= 66, 2, 3))}{p_end}
{phang}{cmd:. gen beta_true = .}{p_end}
{phang}{cmd:. * Group 1: breaks at t=10, t=17; beta = (1, 2, 3)}{p_end}
{phang}{cmd:. replace beta_true = 1 if group0 == 1 & time < 10}{p_end}
{phang}{cmd:. replace beta_true = 2 if group0 == 1 & time >= 10 & time < 17}{p_end}
{phang}{cmd:. replace beta_true = 3 if group0 == 1 & time >= 17}{p_end}
{phang}{cmd:. * Group 2: breaks at t=7, t=17; beta = (3, 4, 5)}{p_end}
{phang}{cmd:. replace beta_true = 3 if group0 == 2 & time < 7}{p_end}
{phang}{cmd:. replace beta_true = 4 if group0 == 2 & time >= 7 & time < 17}{p_end}
{phang}{cmd:. replace beta_true = 5 if group0 == 2 & time >= 17}{p_end}
{phang}{cmd:. * Group 3: no breaks; beta = 1.5}{p_end}
{phang}{cmd:. replace beta_true = 1.5 if group0 == 3}{p_end}
{phang}{cmd:. gen y = x * beta_true + 0.5 * rnormal()}{p_end}
{phang}{cmd:. xtbreakmodel y x, method(gagfl) groups(3)}{p_end}

{pstd}
This DGP from Okui and Wang (2021, Section 4) has 3 groups with heterogeneous
breaks. GAGFL correctly recovers group assignments, break dates (7, 10, 17),
and regime coefficients.{p_end}


{pstd}
{bf:Example 7: Multiple regressors with GAGFL}{p_end}

{phang}{cmd:. clear all}{p_end}
{phang}{cmd:. set seed 54321}{p_end}
{phang}{cmd:. local N = 80}{p_end}
{phang}{cmd:. local T = 15}{p_end}
{phang}{cmd:. set obs `=`N'*`T''}{p_end}
{phang}{cmd:. gen id = ceil(_n/`T')}{p_end}
{phang}{cmd:. bysort id: gen time = _n}{p_end}
{phang}{cmd:. xtset id time}{p_end}
{phang}{cmd:. gen x1 = rnormal()}{p_end}
{phang}{cmd:. gen x2 = rnormal()}{p_end}
{phang}{cmd:. gen b1 = cond(time <= 8, 1, 2)}{p_end}
{phang}{cmd:. gen b2 = cond(time <= 10, 3, -1)}{p_end}
{phang}{cmd:. gen y = x1 * b1 + x2 * b2 + 0.5 * rnormal()}{p_end}
{phang}{cmd:. xtbreakmodel y x1 x2, method(pls)}{p_end}

{pstd}
With two regressors having breaks at different times, PLS (common breaks)
will detect the union of break dates. For coefficient-specific analysis,
consider {helpb xtcbc}.{p_end}


{pstd}
{bf:Example 8: Comparing methods}{p_end}

{phang}{cmd:. * Run all four methods on the same data}{p_end}
{phang}{cmd:. xtbreakmodel y x, method(pls) nograph}{p_end}
{phang}{cmd:. est store pls}{p_end}
{phang}{cmd:. xtbreakmodel y x, method(bfk) nograph}{p_end}
{phang}{cmd:. est store bfk}{p_end}
{phang}{cmd:. xtbreakmodel y x, method(sara) nograph}{p_end}
{phang}{cmd:. est store sara}{p_end}
{phang}{cmd:. xtbreakmodel y x, method(gagfl) groups(3)}{p_end}
{phang}{cmd:. est store gagfl}{p_end}


{pstd}
{bf:Example 9: Accessing stored results}{p_end}

{phang}{cmd:. xtbreakmodel y x1 x2, method(pls) nograph}{p_end}
{phang}{cmd:. display "Number of breaks: " e(nbreaks)[1,1]}{p_end}
{phang}{cmd:. matrix list e(regime)}{p_end}
{phang}{cmd:. matrix list e(alpha)}{p_end}
{phang}{cmd:. display "RMSE = " e(rmse)}{p_end}
{phang}{cmd:. display "Method: " e(method)}{p_end}


{pstd}
{bf:Example 10: Custom tuning for large panels}{p_end}

{phang}{cmd:. xtbreakmodel y x, method(gagfl) groups(4) maxlambda(200) minlambda(0.001) ngrid(80) nsim(100) maxiter(30)}{p_end}

{pstd}
For large panels (N > 500), increase ngrid for finer lambda selection and nsim
for better GFE initialization. Use wider lambda range if the algorithm selects
boudary values.{p_end}


{title:Notes}

{pstd}
{bf:Choosing the number of groups (G).}{p_end}

{pstd}
For GAGFL, the user must specify G. If unknown, estimate for G = 2, 3, ...,
G_max and compare the BIC = SSR/(NT) + sigma^2 * (np_G + N) * ln(NT) / (NT),
where np_G is the total number of group-specific parameters. Choose G
minimizing BIC. Typically, G <= 5 is sufficient for most applications.{p_end}


{pstd}
{bf:When to use which method.}{p_end}

{p 8 12 2}{bf:GAGFL:} Use when heterogeneity across units is expected. This is the
most general and powerful method but requires specifying G and is the most
computationally intensive.{p_end}

{p 8 12 2}{bf:PLS:} Use when all units are expected to share the same break dates.
Good default choice for homogeneous panels. Fast and well-understood
asymptotics.{p_end}

{p 8 12 2}{bf:BFK:} Use as a quick diagnostic. Simple, fast, but limited to sequential
detection (may miss nearby breaks). Good for up to 3 breaks.{p_end}

{p 8 12 2}{bf:SaRa:} Use when robustness to distributional assumptions is important.
Non-parametric approach. Good for detecting breaks in the presence of heavy-tailed
errors or outliers.{p_end}


{pstd}
{bf:Sensitivity to tuning parameters.}{p_end}

{pstd}
For GAGFL/PLS, the key parameter is the IC constant (currently fixed at
c = 0.05 in the information criterion). If too many breaks are detected,
the result may be over-segmented; if too few, under-segmented. The IC is
consistent as N -> infinity with T fixed, so for small N, results should be
interpreted carefully.{p_end}


{pstd}
{bf:Computational considerations.}{p_end}

{pstd}
GAGFL complexity: O(nGrid * maxIter * G * T * N * K). For N=100, T=20, G=3,
K=1, nGrid=40: approximately 30 seconds. For larger panels, reduce nGrid or
use PLS first for exploratory analysis.{p_end}


{pstd}
{bf:Comparison with xtcbc.}{p_end}

{pstd}
{cmd:xtbreakmodel} uses {bf:vector breaks}: all K coefficients break simultaneously
at each break date. {cmd:xtcbc} (Kaddoura, 2025) allows {bf:coefficient-by-coefficient}
breaks where each regressor has its own break schedule. If you suspect different
regressors break at different times, use {cmd:xtcbc} instead.{p_end}


{pstd}
{bf:Balanced panels required.}{p_end}

{pstd}
The current implementation requires strongly balanced panels. For unbalanced
panels, balance first using {helpb tsfill} or imputation methods. See
{helpb xtmispanel} for panel imputation tools.{p_end}


{pstd}
{bf:Time-series operators.}{p_end}

{pstd}
{cmd:xtbreakmodel} supports Stata time-series operators in the variable list,
including {cmd:L.} (lag), {cmd:D.} (difference), and {cmd:F.} (forward). Ensure
that applying operators does not create gaps in the panel.{p_end}


{title:References}

{phang}
Okui, R. and Wang, Y. (2021). Heterogeneous structural breaks in panel data
models. {it:Journal of Econometrics}, 220(2), 447-473.{p_end}

{phang}
Qian, J. and Su, L. (2016). Shrinkage estimation of common breaks in panel
data models via adaptive group fused lasso. {it:Journal of Econometrics},
191(1), 86-109.{p_end}

{phang}
Baltagi, B. H., Feng, Q. and Kao, C. (2016). Estimation of heterogeneous
panels with structural breaks. {it:Journal of Econometrics}, 191(1), 176-195.{p_end}

{phang}
Li, J., Xiao, Z. and Chen, J. (2025). Screening and ranking algorithm for
change-point detection in panel data. Working Paper.{p_end}

{phang}
Bonhomme, S. and Manresa, E. (2015). Grouped patterns of heterogeneity in
panel data. {it:Econometrica}, 83(3), 1147-1184.{p_end}

{phang}
Bai, J. and Perron, P. (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica}, 66(1), 47-78.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{p_end}
{pstd}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite as:{p_end}
{pstd}
Roudane, M. (2026). xtbreakmodel: Stata module for heterogeneous structural
breaks in panel data models.{p_end}


{title:Also see}

{psee}
{helpb xtcbc}, {helpb xtpmg}, {helpb xtlmbreak}, {helpb xtset}, {helpb regress}
{p_end}
