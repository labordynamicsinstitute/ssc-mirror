{smcl}
{* *! cobreakcoint.sthlp — v1.0.0 — 2026-04-18}{...}
{vieweralsosee "xtbreakcoint" "help xtbreakcoint"}{...}
{vieweralsosee "cupfm" "help cupfm"}{...}
{vieweralsosee "vecrank" "help vecrank"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "cobreakcoint##syntax"}{...}
{viewerjumpto "Description" "cobreakcoint##description"}{...}
{viewerjumpto "Background" "cobreakcoint##background"}{...}
{viewerjumpto "Models" "cobreakcoint##models"}{...}
{viewerjumpto "Tests" "cobreakcoint##tests"}{...}
{viewerjumpto "Options" "cobreakcoint##options"}{...}
{viewerjumpto "Interpretation" "cobreakcoint##interpretation"}{...}
{viewerjumpto "Data requirements" "cobreakcoint##data"}{...}
{viewerjumpto "Examples" "cobreakcoint##examples"}{...}
{viewerjumpto "Stored results" "cobreakcoint##stored"}{...}
{viewerjumpto "Acknowledgements" "cobreakcoint##acknowledgements"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:cobreakcoint} {hline 2}}Quasi-Likelihood Ratio Tests for Cointegration,
Cobreaking, and Cotrending{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:cobreakcoint} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt model(1|2)}}deterministic specification; default is {bf:2}{p_end}
{synopt:{opt maxb:reaks(#)}}maximum breaks to test: 0, 1, or 2; default is {bf:2}{p_end}
{synopt:{opt klags(numlist)}}DOLS lag/lead values; default is {bf:1 3 5 7 9}{p_end}
{synopt:{opt epsilon(real)}}trimming fraction; default is {bf:0.15}{p_end}

{syntab:Output}
{synopt:{opt plot}}produce diagnostic visualization plots{p_end}
{synopt:{opt notable}}suppress output tables{p_end}
{synopt:{opt saving(string)}}filename stem for saved graphs{p_end}
{synopt:{opt noisily}}display verbose Mata computation output{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cobreakcoint} implements quasi-likelihood ratio (QLR) tests for the joint
analysis of {bf:cointegration}, {bf:cobreaking}, and {bf:cotrending} in a bivariate
or multivariate system of I(1) variables that may contain structural breaks in
their deterministic components.

{pstd}
In applied macroeconomics and finance, researchers often test whether two
non-stationary (I(1)) variables share a long-run equilibrium (cointegration).
However, many macroeconomic time series exhibit structural breaks — permanent
shifts in their means or trends caused by policy changes, economic crises, or
institutional reforms. Standard cointegration tests (e.g., Engle-Granger, Johansen)
can produce misleading results when such breaks are present.

{pstd}
This command addresses three fundamental questions simultaneously:

{p 8 12 2}
{bf:Q1. Do the variables cointegrate?} (Even if structural breaks are present)
{break}The {bf:Qr test} answers this question robustly, meaning it controls size
regardless of whether breaks exist.{p_end}

{p 8 12 2}
{bf:Q2. Do the variables cobreak?} (Do breaks cancel in the long-run relationship?)
{break}The {bf:Qcb test} answers whether both cointegration AND cobreaking hold jointly.
If H0 is not rejected, the breaks in individual series cancel out in the equilibrium.{p_end}

{p 8 12 2}
{bf:Q3. Do the variables cotrend?} (Do the trends cancel?)
{break}The {bf:Qct test} (Model II only) answers whether both cointegration AND cotrending
hold jointly. If H0 is not rejected, the deterministic trends in individual series
share a common stochastic trend.{p_end}


{marker background}{...}
{title:Background and Key Concepts}

{dlgtab:Cointegration (CI)}

{pstd}
Two I(1) variables y_t and x_t are {bf:cointegrated} if there exists a linear
combination y_t - beta*x_t = u_t that is stationary (I(0)). This means the
variables share a common stochastic trend and move together in the long run.

{pstd}
{bf:Example:} Government expenditures (E) and revenues (R) may individually wander
as random walks, but if they are cointegrated, the budget deficit E - beta*R is
stationary, implying a sustainable fiscal policy.

{dlgtab:Cobreaking (CB)}

{pstd}
Two I(1) variables with structural breaks are said to {bf:cobreak} if the breaks
in y_t and x_t cancel out in the long-run relationship y_t - beta*x_t. That is,
even though each series individually has level shifts, the equilibrium error
does not exhibit those shifts.

{pstd}
{bf:Example:} If both E and R shift upward around 1967 due to the Great Society
programs, but the deficit (E - beta*R) remains unaffected, then E and R cobreak.

{pstd}
{bf:Intuition:} Cobreaking means the structural breaks have the same "direction and
magnitude" in both series (after scaling by beta), so they wash out in the
equilibrium relationship.

{dlgtab:Cotrending (CT)}

{pstd}
Two I(1) variables with deterministic trends are said to {bf:cotrend} if the
trends cancel in the long-run relationship. This is relevant only for {bf:Model II}
which includes a linear trend in the deterministic specification.

{pstd}
{bf:Example:} If both E and R have deterministic upward trends (e.g., due to
steady GDP growth), and these trends cancel in E - beta*R, then the series cotrend.

{dlgtab:Structural Breaks}

{pstd}
A {bf:structural break} is a permanent, discrete change in the deterministic
component of a time series. In the context of this command:

{p 8 12 2}
- Model I breaks are {bf:level shifts} (mean shifts): the series jumps to a
  new level at the break date.{p_end}
{p 8 12 2}
- Model II breaks are {bf:intercept shifts with trend}: the intercept changes
  but the linear trend coefficient remains the same.{p_end}

{pstd}
The break dates can be either {bf:known} (specified by the researcher) or
{bf:unknown} (estimated from the data by maximizing the log-likelihood).

{dlgtab:DOLS Endogeneity Correction}

{pstd}
The Dynamic OLS (DOLS) method of Saikkonen (1991) and Stock & Watson (1993)
corrects for endogeneity by including leads and lags of the first-differenced
regressors in the cointegrating regression:

{p 8 12 2}
y_t = beta*x_t + d_t'*gamma + SUM_{j=-k}^{k} delta_j * Dx_{t-j} + u_t{p_end}

{pstd}
The parameter {opt klags()} controls k. Multiple values are recommended to
assess sensitivity. The paper uses k = 1, 3, 5, 7, 9.

{dlgtab:Lambda-bar (Lbar) Parameter}

{pstd}
The test statistics use a {it:quasi-likelihood ratio} approach where the
alternative hypothesis is parameterized by theta = 1 - Lbar/T. The Lbar
values are calibrated from the asymptotic distribution tables to maximize
power. They depend on the model, number of breaks, and number of regressors.

{dlgtab:Long-run Variance Estimation}

{pstd}
The long-run variance of the residuals is estimated using the {bf:Quadratic
Spectral (QS) kernel} with the data-dependent bandwidth of Andrews (1991).
This provides a consistent estimate of the spectral density at frequency zero,
which is needed because the cointegrating residuals may be serially correlated.


{marker models}{...}
{title:Model Specifications}

{dlgtab:Model I — Mean Shifts}

{pstd}
The data generating process is:

{p 8 12 2}
y_t = beta*x_t + mu_0 + SUM_{j=1}^{m} mu_j * DU_t(T_j) + u_t{p_end}

{pstd}
where DU_t(T_j) = 1 if t > T_j, 0 otherwise. The breaks are pure level shifts.
There is {bf:no linear trend} in Model I. The cotrending test (Qct) is not
available under Model I.

{pstd}
{bf:Use Model I when:} your data has no deterministic trend but may have
permanent level shifts (e.g., exchange rates, interest rate spreads).

{dlgtab:Model II — Trend with Intercept Shifts}

{pstd}
The data generating process is:

{p 8 12 2}
y_t = beta*x_t + mu_0 + SUM_{j=1}^{m} mu_j * DU_t(T_j) + omega*t + u_t{p_end}

{pstd}
This includes a {bf:linear deterministic trend} (omega*t) plus intercept shifts.
All three tests (Qr, Qcb, Qct) are available.

{pstd}
{bf:Use Model II when:} your data exhibits trending behavior plus possible level
shifts (e.g., GDP ratios, government budget variables, consumption-income ratios).


{marker tests}{...}
{title:Test Statistics}

{dlgtab:Qr — Robust Cointegration Test}

{pstd}
{bf:Null hypothesis:} y_t and x_t are cointegrated (u_t is I(0)).

{pstd}
{bf:Key feature:} The Qr statistic is {bf:robust to the presence or absence of
structural breaks}. Its asymptotic distribution does not depend on whether
cobreaking or cotrending holds. This means:

{p 8 12 2}
- You do NOT need to know the number of breaks{p_end}
{p 8 12 2}
- You do NOT need to know the break dates{p_end}
{p 8 12 2}
- The test has correct size regardless of break structure{p_end}

{pstd}
{bf:Reject H0 if:} Qr > critical value. Rejection means no cointegration.

{pstd}
The Qr statistic is computed for each number of breaks (m = 0, 1, 2) with
unknown break dates. The break date is estimated under H0 of cointegration
by minimizing the sum of squared residuals.

{dlgtab:Qcb — Joint CI and Cobreaking Test}

{pstd}
{bf:Null hypothesis:} y_t and x_t are cointegrated AND the structural breaks
cancel in the cointegrating relationship (cobreaking holds).

{pstd}
Under H0, the break coefficients mu_1 = ... = mu_m = 0 in the cointegrating
regression. The test includes a penalty term m*ln(T) which arises from the
information criterion used to determine the break number.

{pstd}
{bf:Reject H0 if:} Qcb > critical value. Three possible interpretations
of rejection:

{p 8 12 2}
(a) No cointegration, or{p_end}
{p 8 12 2}
(b) Cointegration holds but cobreaking does not (breaks do NOT cancel), or{p_end}
{p 8 12 2}
(c) Both fail.{p_end}

{pstd}
{bf:Key insight:} If you {it:reject} Qcb but {it:fail to reject} Qr, then
cointegration holds BUT cobreaking does not. The breaks persist in the
equilibrium relationship.

{dlgtab:Qct — Joint CI and Cotrending Test}

{pstd}
{bf:Null hypothesis:} y_t and x_t are cointegrated AND cotrending holds
(the deterministic trends cancel). Only available under {bf:Model II}.

{pstd}
Under H0, both mu_1 = ... = mu_m = 0 and omega = 0. The penalty is
(m+2)*ln(T) plus an adjustment for the trending regressors.

{pstd}
{bf:Reject H0 if:} Qct > critical value. Rejection means either no
cointegration, no cotrending, or both.

{dlgtab:Dmax_cb and Dmax_ct — Double-Maximum Tests}

{pstd}
The {bf:Dmax} statistics are omnibus tests that do not require specifying
the number of breaks. They are computed as:

{p 8 12 2}
Dmax_cb = max over m=0,...,M of (Qcb(m) - a_m) / b_m{p_end}

{pstd}
where a_m and b_m are the 95th percentile and scale factor from the asymptotic
distribution. The Dmax statistic follows a Type I extreme value distribution.

{pstd}
{bf:Advantage:} Dmax is valid across all possible numbers of breaks, so you
do not need to choose m.


{marker options}{...}
{title:Options}

{phang}
{opt model(1|2)} specifies the deterministic specification:

{p 12 16 2}
{bf:1} = Model I: mean shifts only (DU dummies). No trend. No Qct test.{p_end}
{p 12 16 2}
{bf:2} = Model II: linear trend with intercept shifts. All tests available. {bf:Default.}{p_end}

{phang}
{opt maxbreaks(#)} sets the maximum number of structural breaks to consider.
With maxbreaks(2), the command computes tests for m=0, 1, and 2 breaks and
reports the Dmax omnibus statistics. Default is {bf:2}.

{phang}
{opt klags(numlist)} specifies the DOLS lag/lead values. Results are reported for
each value separately. Using multiple values allows assessing sensitivity of the
results to the bandwidth choice. Default is {bf:1 3 5 7 9}.

{pstd}
{bf:Guidance on choosing k:}

{p 12 16 2}
- Larger k reduces bias from endogeneity but costs degrees of freedom{p_end}
{p 12 16 2}
- With T=100, k=1 to 5 is reasonable; with T=250, k up to 9{p_end}
{p 12 16 2}
- Results should be qualitatively similar across different k values{p_end}

{phang}
{opt epsilon(real)} sets the trimming fraction for the break date search.
Break dates are searched over [epsilon*T, (1-epsilon)*T]. Default is {bf:0.15},
meaning the first and last 15% of observations are excluded.

{phang}
{opt plot} produces diagnostic plots:

{p 12 16 2}
(1) Bar charts of Qr, Qcb, Qct statistics across lag specs with CV lines{p_end}
{p 12 16 2}
(2) Time series plot with estimated break dates marked{p_end}
{p 12 16 2}
(3) Combined dashboard{p_end}

{phang}
{opt notable} suppresses output tables (results still stored in e()).

{phang}
{opt saving(string)} specifies a filename stem for saving plots as PNG files.

{phang}
{opt noisily} displays detailed progress during Mata computation.


{marker interpretation}{...}
{title:How to Interpret the Results}

{pstd}
The following decision tree helps interpret the test results:

{p 4 8 2}
{bf:Step 1:} Look at the {bf:Qr test} across all lag specifications.{p_end}

{p 8 12 2}
{bf:If Qr is NOT significant} (Qr < CV): {bf:Cointegration holds.}
The variables share a long-run equilibrium. Proceed to Step 2.{p_end}

{p 8 12 2}
{bf:If Qr IS significant} (Qr > CV): {bf:No cointegration.}
The variables do not share a long-run equilibrium. The analysis stops here.{p_end}

{p 4 8 2}
{bf:Step 2:} (If CI holds) Look at the {bf:Qcb test}.{p_end}

{p 8 12 2}
{bf:If Qcb is NOT significant:} {bf:Cobreaking holds.}
The structural breaks cancel in the equilibrium. The long-run relationship
is free of structural breaks, making it more reliable for forecasting.{p_end}

{p 8 12 2}
{bf:If Qcb IS significant:} {bf:Cobreaking fails.}
Although cointegration holds, the structural breaks do NOT cancel. The
equilibrium relationship itself is subject to regime changes.{p_end}

{p 4 8 2}
{bf:Step 3:} (If CI holds, Model II only) Look at the {bf:Qct test}.{p_end}

{p 8 12 2}
{bf:If Qct is NOT significant:} {bf:Cotrending holds.}
The deterministic trends cancel. The equilibrium has no drift.{p_end}

{p 8 12 2}
{bf:If Qct IS significant:} {bf:Cotrending fails.}
The equilibrium has a non-zero drift (trend in the residuals).{p_end}

{p 4 8 2}
{bf:Step 4:} Look at {bf:Dmax} for robustness.{p_end}

{p 8 12 2}
Dmax provides a check that does not depend on the assumed number of breaks.
If Dmax is significant while the individual Q tests are borderline, the
overall evidence against the null is stronger.{p_end}

{dlgtab:Interpreting Break Dates}

{pstd}
The estimated break dates are reported as both calendar dates and fractions
(pi = Tb/T). Break dates are estimated {it:under the null of cointegration},
so they represent the most likely locations of structural breaks in the
deterministic component of the cointegrating relationship.

{pstd}
{bf:Robustness check:} If the estimated break dates are stable across different
lag specifications (k), this provides stronger evidence for the break locations.
If dates shift substantially, the break evidence is weaker.

{dlgtab:Significance Stars}

{pstd}
Stars are assigned based on asymptotic critical values from the paper:

{p 8 12 2}
*** = significant at 1% level (strong evidence against H0){p_end}
{p 8 12 2}
**  = significant at 5% level (moderate evidence against H0){p_end}
{p 8 12 2}
*   = significant at 10% level (weak evidence against H0){p_end}


{marker data}{...}
{title:Data Requirements and Assumptions}

{dlgtab:Required Data Structure}

{p 8 12 2}
1. {bf:Time-series data:} The dataset must be {cmd:tsset} with a time variable.
   Panel data is not supported.{p_end}

{p 8 12 2}
2. {bf:I(1) variables:} Both the dependent and independent variables should be
   integrated of order one (unit root). Run {cmd:dfuller} or {cmd:pperron}
   first to verify.{p_end}

{p 8 12 2}
3. {bf:Minimum sample size:} At least 50 observations. With T < 100, use
   smaller k values. The paper uses T = 254 (quarterly data).{p_end}

{p 8 12 2}
4. {bf:Regressors:} 1 or 2 stochastic (I(1)) regressors (px = 1 or 2).{p_end}

{dlgtab:Key Assumptions}

{p 8 12 2}
1. {bf:I(1) variables:} All variables must be non-stationary with a unit root.
   If variables are I(0), use standard regression methods instead.{p_end}

{p 8 12 2}
2. {bf:At most 2 breaks:} The current implementation supports 0, 1, or 2
   structural breaks. If you suspect more breaks, the test may not detect them.{p_end}

{p 8 12 2}
3. {bf:Break type:} Breaks are in the deterministic component only (level shifts
   or intercept shifts). The cointegrating slope coefficient beta is assumed
   constant across regimes.{p_end}

{p 8 12 2}
4. {bf:Single equation:} The command estimates a single cointegrating equation.
   For systems with multiple cointegrating vectors, use {cmd:vecrank}.{p_end}

{p 8 12 2}
5. {bf:No I(2) variables:} Variables integrated of order 2 or higher are not
   handled. First-difference such variables before use.{p_end}

{dlgtab:Pre-testing Recommendations}

{pstd}
Before running {cmd:cobreakcoint}, we recommend:

{p 8 12 2}
(a) Test each variable for unit roots: {cmd:dfuller y, lags(4)}
    and {cmd:dfuller D.y, lags(4)} to confirm I(1).{p_end}

{p 8 12 2}
(b) Plot the series to visually identify potential break dates
    and assess whether Model I or Model II is appropriate.{p_end}

{p 8 12 2}
(c) For trending data, use Model II. For mean-reverting data with
    possible level shifts, use Model I.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: US Government Budget Sustainability}

{pstd}
This example replicates the empirical application from the original paper.
The data contains quarterly US government expenditures and revenues as
percentages of GDP from 1947:Q1 to 2010:Q2 (T = 254).

{pstd}
{bf:Research question:} Is US fiscal policy sustainable? That is, do government
expenditures (E) and revenues (R) share a long-run equilibrium (cointegration)?
And if so, do the structural breaks (e.g., Great Society, Reagan tax cuts)
cancel in the equilibrium (cobreaking)?

{phang}{cmd:. * Load bundled dataset}{p_end}
{phang}{cmd:. use USbudget.dta, clear}{p_end}

{phang}{cmd:. * Verify unit roots}{p_end}
{phang}{cmd:. dfuller E, lags(4)}{p_end}
{phang}{cmd:. dfuller R, lags(4)}{p_end}
{phang}{cmd:. * Both should fail to reject H0 of unit root}{p_end}

{phang}{cmd:. * Run Model II (appropriate for trending GDP ratios)}{p_end}
{phang}{cmd:. cobreakcoint E R, model(2) maxbreaks(2) klags(1 3 5 7 9)}{p_end}

{pstd}
{bf:Expected results and interpretation:}

{p 8 12 2}
Qr(1) ranges from 13-15 across lags, all *** significant.
{bf:Interpretation:} Reject H0 of cointegration. This means E and R do NOT
cointegrate — fiscal policy is not sustainable in the conventional sense.{p_end}

{p 8 12 2}
Qcb(1) ranges from 17-18, all ** significant.
{bf:Interpretation:} The joint hypothesis of CI + CB is also rejected.{p_end}

{p 8 12 2}
Qct(1) ranges from 22-33, all significant.
{bf:Interpretation:} The joint hypothesis of CI + CT + CB is also rejected.{p_end}

{p 8 12 2}
Break dates: m=1 break around 1996q1 (pi=0.78), m=2 breaks around
1966q3 and 1996q1. These correspond to the mid-1960s fiscal expansion
and the mid-1990s budget surplus era.{p_end}

{pstd}
{bf:Example 2: With diagnostic plots}

{phang}{cmd:. cobreakcoint E R, model(2) maxbreaks(2) plot saving(budget)}{p_end}

{pstd}
This produces bar charts of all test statistics with critical value reference
lines, time series with estimated break dates marked, and a combined dashboard.

{pstd}
{bf:Example 3: Model I — Mean shifts only}

{phang}{cmd:. cobreakcoint E R, model(1) maxbreaks(2) klags(1 3 5 7 9)}{p_end}

{pstd}
Model I assumes no deterministic trend, only level shifts. The Qct test is
not available. Use this when the data does not exhibit a clear linear trend.

{pstd}
{bf:Example 4: Custom lag specification}

{phang}{cmd:. cobreakcoint E R, model(2) klags(2 4 6 8) maxbreaks(1)}{p_end}

{pstd}
Only search for 0 or 1 break with even lag/lead values. Faster computation.

{pstd}
{bf:Example 5: Accessing stored results}

{phang}{cmd:. cobreakcoint E R, model(2) maxbreaks(2) klags(1 3)}{p_end}
{phang}{cmd:. matrix list e(TestM)          // all test statistics}{p_end}
{phang}{cmd:. matrix list e(ACV5)           // 5% critical values}{p_end}
{phang}{cmd:. matrix list e(Bmat)           // break dates (obs numbers)}{p_end}
{phang}{cmd:. matrix list e(Bfrac)          // break fractions}{p_end}
{phang}{cmd:. display e(model)              // model number}{p_end}
{phang}{cmd:. display e(T)                  // sample size}{p_end}
{phang}{cmd:. ereturn list                  // all stored results}{p_end}

{pstd}
{bf:Example 6: Using your own data}

{phang}{cmd:. * Load your time series data}{p_end}
{phang}{cmd:. use mydata.dta, clear}{p_end}
{phang}{cmd:. tsset time_variable}{p_end}
{phang}{cmd:. * Check unit roots first}{p_end}
{phang}{cmd:. dfuller y, lags(4)}{p_end}
{phang}{cmd:. dfuller x, lags(4)}{p_end}
{phang}{cmd:. * Run tests}{p_end}
{phang}{cmd:. cobreakcoint y x, model(2) maxbreaks(2) klags(1 3 5 7)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:cobreakcoint} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Scalars}{p_end}
{synopt:{cmd:e(T)}}number of observations{p_end}
{synopt:{cmd:e(px)}}number of stochastic regressors{p_end}
{synopt:{cmd:e(model)}}model type (1 or 2){p_end}
{synopt:{cmd:e(maxbreaks)}}maximum breaks tested{p_end}
{synopt:{cmd:e(nk)}}number of lag/lead specifications{p_end}

{p2col 5 22 24 2: Matrices}{p_end}
{synopt:{cmd:e(TestM)}}nk x 12 matrix of test statistics:{p_end}
{p 12 12 2}
Columns 1-3: Q01, Q02, Q03 (m=0 known break tests: Qr, Qcb, Qct){p_end}
{p 12 12 2}
Columns 4-6: Q11, Q12, Q13 (m=1 unknown break tests){p_end}
{p 12 12 2}
Columns 7-9: Q21, Q22, Q23 (m=2 unknown break tests){p_end}
{p 12 12 2}
Column 10: Dmax_cb (Double-max for cobreaking){p_end}
{p 12 12 2}
Column 11: Dmax_ct (Double-max for cotrending){p_end}
{p 12 12 2}
Column 12: k (DOLS lags/leads value){p_end}

{synopt:{cmd:e(ACV5)}}1 x 12 vector of 5% asymptotic critical values{p_end}
{synopt:{cmd:e(Bmat)}}nk x 6 matrix of estimated break dates (obs numbers){p_end}
{synopt:{cmd:e(Bfrac)}}nk x 5 matrix of estimated break fractions (Tb/T){p_end}

{p2col 5 22 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cobreakcoint}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvars)}}independent variable names{p_end}
{synopt:{cmd:e(klags)}}DOLS lags/leads specification{p_end}
{synopt:{cmd:e(modtype)}}model type description{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}


{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
This command is a faithful Stata/Mata translation of the original MATLAB code
accompanying "{it:Quasi-likelihood ratio tests for cointegration, cobreaking,
and cotrending}" published in {it:Econometric Reviews}, 2019, 38(1), 43-61.

{pstd}
The test methodology and asymptotic critical values are from the original paper.
The DOLS correction follows Saikkonen (1991). The long-run variance estimator
uses the Quadratic Spectral kernel with Andrews (1991) bandwidth.

{pstd}
The bundled dataset ({bf:USbudget.dta}) contains quarterly US government revenues
and expenditures as percentages of GDP, 1947:Q1 to 2010:Q2 (T = 254), sourced
from the NIPA tables of the Bureau of Economic Analysis (BEA).


{title:Also see}

{psee}
{space 2}Help: {helpb dfuller}, {helpb pperron}, {helpb vecrank},
{helpb zandrews}, {helpb cupfm}
{p_end}
