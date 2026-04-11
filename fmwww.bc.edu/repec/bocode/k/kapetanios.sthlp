{smcl}
{* *! version 3.2  2026}{...}
{viewerjumpto "Syntax" "kapetanios##syntax"}{...}
{viewerjumpto "Description" "kapetanios##description"}{...}
{viewerjumpto "Test procedure" "kapetanios##procedure"}{...}
{viewerjumpto "Options" "kapetanios##options"}{...}
{viewerjumpto "Lag selection" "kapetanios##lagsel"}{...}
{viewerjumpto "Remarks" "kapetanios##remarks"}{...}
{viewerjumpto "Stored results" "kapetanios##results"}{...}
{viewerjumpto "Examples" "kapetanios##examples"}{...}
{viewerjumpto "References" "kapetanios##references"}{...}
{viewerjumpto "Author" "kapetanios##author"}{...}

{title:Title}

{phang}
{bf:kapetanios} {hline 2} Kapetanios (2005) unit-root test with up to 5 structural breaks

{right:Version 3.2.0}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:kapetanios} {varname} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt:{opt b:reaks(#)}}maximum number of structural breaks (1–5); default is {bf:3}{p_end}
{synopt:{opt k:max(#)}}maximum number of lags; default is floor(4*(T/100)^0.25){p_end}
{synopt:{opt e:psilon(#)}}trimming parameter; default is {bf:0.1}{p_end}
{synopt:{opt m:odel(#)}}model specification: 1, 2, or 3; default is {bf:3}{p_end}
{synopt:{opt lags:el(method)}}lag selection method: {bf:ttest} (default), {bf:bg}, {bf:aic}, or {bf:bic}{p_end}
{synopt:{opt bgl:ags(#)}}max lags in BG test; default depends on data frequency{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:kapetanios} implements the unit-root test proposed by Kapetanios (2005),
which tests the null hypothesis of a unit root against the alternative of a
trend-stationary process with up to 5 structural breaks in the intercept
and/or trend. The test extends the single-break tests of Zivot and Andrews (1992)
and the two-break test of Lumsdaine and Papell (1997) to an arbitrary number of
breaks, while remaining computationally efficient through the sequential break
estimation strategy of Bai and Perron (1998).

{pstd}
Unlike tests that fix the number of breaks in advance, {cmd:kapetanios} searches
for the actual number of breaks (up to 5, or the user-specified maximum),
making it less dependent on a priori assumptions about the break structure.

{pstd}
The data must be declared as time series using {helpb tsset} before calling
{cmd:kapetanios}.

{pstd}
{ul:Note on gaps in time series:} For time series with gaps (e.g. daily
financial data with weekends and holidays excluded), {cmd:kapetanios} treats
observations as consecutive integers, ignoring calendar gaps. Users should
be aware of this when interpreting break dates and should ensure the data
is appropriately structured before running the test.

{pstd}
This program is largely a translation of the Gretl package
Kapetanios v2.1 (2022-04-11) by Andrea E. Sánchez Urbina,
Ricardo Ramírez and Daniel Ventosa-Santaulària to Stata,
with the following extensions:

{pstd}
{ul:Differences between the Gretl Kapetanios package and {cmd:kapetanios}:}

{phang2}1. {cmd:kapetanios} offers Breusch-Godfrey (BG) based lag selection via
a general-to-specific (GTS) procedure ({bf:lagsel(bg)}), which directly
targets the elimination of serial correlation in test residuals.{p_end}

{phang2}2. {cmd:kapetanios} offers AIC-based lag selection ({bf:lagsel(aic)}).{p_end}

{phang2}3. {cmd:kapetanios} offers BIC-based lag selection ({bf:lagsel(bic)}).{p_end}

{phang2}4. For {bf:lagsel(aic)} and {bf:lagsel(bic)}, a post-selection BG test is
automatically performed using the estimated break dates, and a warning is
issued if residual autocorrelation remains.{p_end}


{marker procedure}{...}
{title:Test procedure}

{pstd}
{ul:Test regression}

{pstd}
The test is based on the following augmented Dickey-Fuller type regression:

{pmore}
y_t = mu_0 + mu_1*t + alpha*y_{t-1} + sum_{i=1}^{k} c_i*Delta y_{t-i}
      + sum_{i=1}^{m} phi_i*DU_{i,t} + sum_{i=1}^{m} psi_i*DT_{i,t} + e_t

{pstd}
where the break dummies are defined as:

{pmore}
DU_{i,t} = 1(t > T_{b,i})                        (intercept break){break}
DT_{i,t} = 1(t > T_{b,i}) * (t - T_{b,i})        (trend break)

{pstd}
with T_{b,i} denoting the date of the i-th structural break, and 1(.) being
the indicator function. The null hypothesis is H0: alpha = 1 (unit root).
The test statistic s_min is the minimum t-ratio on alpha over all estimated
break configurations. Rejection of H0 implies trend stationarity with structural
breaks.

{pstd}
{ul:Break search algorithm}

{pstd}
The procedure follows the sequential strategy of Bai and Perron (1998), which
requires only O(T) least squares operations for any given number of breaks:

{phang2}Step 1. Search for a single break over all feasible observation windows
(determined by the trimming parameter epsilon). For each candidate break date,
estimate the test regression and store the t-statistic and SSR.{p_end}

{phang2}Step 2. Select the break date that minimizes the SSR. This is the
first estimated break.{p_end}

{phang2}Step 3. Conditioning on the first break, search for a second break
over the remaining feasible windows (excluding a neighbourhood of the first
break of width epsilon*T). Choose the second break by minimizing the SSR.{p_end}

{phang2}Step 4. Repeat until {it:m} break dates have been estimated, or until
no more feasible windows remain.{p_end}

{phang2}Step 5. The test statistic is the minimum t-statistic across all
estimated break configurations: s_min = min{s_1, s_2, ..., s_m}.{p_end}

{pstd}
{ul:Critical values}

{pstd}
Critical values are reproduced from Table I of Kapetanios (2005), obtained
by simulation with T = 250 observations and 1000 replications under the unit
root null. Three model specifications are covered:

{phang2}Model A (model(1)): intercept breaks only{p_end}
{phang2}Model B (model(2)): trend breaks only{p_end}
{phang2}Model C (model(3)): both intercept and trend breaks (default){p_end}

{pstd}
Critical values are provided for up to m = 5 breaks at the 10%, 5%, and 1%
significance levels.


{marker options}{...}
{title:Options}

{phang}
{opt breaks(#)} specifies the maximum number of structural breaks to search
for. Must be an integer between 1 and 5. Default is {bf:3}. The actual number
of breaks found may be less than {it:m} if the procedure exhausts all feasible
observation windows. As shown in Kapetanios (2005), the power of the test
generally decreases as {it:m} increases, so {it:m} should be guided by
economic considerations.

{phang}
{opt kmax(#)} specifies the maximum number of lagged first differences to
include in the test regression. Lag length is selected automatically according
to the method in {opt lagsel()}. If not specified, the default is
floor(4*(T/100)^0.25) for the {bf:ttest} method, and the Schwert (1989) rule
floor(12*(T/100)^0.5) for {bf:bg}, {bf:aic}, and {bf:bic}.

{phang}
{opt epsilon(#)} specifies the trimming parameter. At each break search step,
the first and last epsilon*T observations are excluded as candidate break dates.
Must be strictly between 0 and 0.5. Default is {bf:0.1}. If the chosen value
does not allow for any breaks given T, it is automatically adjusted to the
maximum feasible value.

{phang}
{opt model(#)} specifies the deterministic components included in the break
dummies:

{phang2}{bf:1} — Only intercept break dummies (DU). Model A in Kapetanios (2005).
Suitable when breaks affect only the level of the series.

{phang2}{bf:2} — Only trend break dummies (DT). Model B in Kapetanios (2005).
Suitable when breaks affect only the slope of the trend.

{phang2}{bf:3} — Both intercept and trend break dummies (DU and DT). Model C
in Kapetanios (2005). The most general specification and the default.


{marker lagsel}{...}
{title:Lag selection}

{pstd}
{cmd:kapetanios} offers four methods for selecting the lag length k. As discussed
in Kapetanios (2005), k may be treated as known or selected by a data-dependent
procedure. Ng and Perron (1995) show that both information criteria and sequential
testing procedures yield the same asymptotic distribution for the test statistic,
provided k is allowed to grow at appropriate rates.

{phang}
{opt lagsel(ttest)} {bf:(default)} — Sequential t-test of Ng and Perron (1995),
as used in Zivot and Andrews (1992) and Kapetanios (2005). Starting from
{it:kmax} downward, the t-statistic on the last included lag is evaluated.
The procedure stops at the first K for which |t| > 1.6 and selects that K.
If no lag satisfies this criterion, K = 0 is selected.

{phang}
{opt lagsel(bg)} — General-to-specific (GTS) selection based on the
Breusch-Godfrey LM test for serial correlation ({helpb estat bgodfrey}).
Starting from {it:kmax} downward, the BG test is applied to residuals at
lags 1 through {it:bglags}. If autocorrelation is detected at any lag
(p < 0.05), the procedure retains the previous lag length. This method
directly targets the elimination of serial correlation, which is the primary
purpose of including lagged differences in the test regression.

{phang}
{opt lagsel(aic)} — Selects the lag that minimizes the Akaike Information
Criterion: AIC = log(SSR/n) + 2k/n. After selection, residuals are automatically
tested for autocorrelation using the BG test. A warning is issued if
autocorrelation remains.

{phang}
{opt lagsel(bic)} — Selects the lag that minimizes the Bayesian Information
Criterion: BIC = log(SSR/n) + k*log(n)/n. BIC penalises additional parameters
more heavily than AIC and typically selects more parsimonious models. A BG
autocorrelation check is performed after selection, as with {bf:lagsel(aic)}.

{phang}
{opt bglags(#)} — Maximum lag order in the BG test (for {bf:lagsel(bg)}) and
in the post-selection autocorrelation check (for {bf:lagsel(aic/bic)}). Default
is automatically set to span two years: 8 for quarterly, 24 for monthly,
52 for weekly, 100 for daily, and 2 for annual data.


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Lag selection and serial correlation}

{pstd}
The purpose of including lagged first differences in the test regression is to
eliminate serial correlation in the residuals, which would otherwise distort the
asymptotic distribution of the test statistic. Kapetanios (2005) follows the
sequential t-test of Ng and Perron (1995), which selects the lag length based
on the significance of the last included lag (|t| > 1.6) rather than directly
testing for residual autocorrelation. Ng and Perron (1995) show that this
procedure is asymptotically valid — that is, it eliminates serial correlation
at the rate required for the test statistic to converge to its limiting
distribution.

{pstd}
In finite samples, however, the sequential t-test does not guarantee the absence
of residual autocorrelation at the selected lag length. The {bf:lagsel(bg)} option
addresses this by directly testing residuals for serial correlation using the
Breusch-Godfrey LM test in a general-to-specific (GTS) framework. This approach
is more conservative in the sense that it explicitly verifies the elimination of
autocorrelation rather than relying on an indirect criterion. When {bf:lagsel(bg)}
is specified, the BG test is applied at each lag order from 1 to {it:bglags}
separately. Testing at lag {it:p} corresponds to checking for AR({it:p})-type
autocorrelation in the residuals. By testing at all lags from 1 to {it:bglags},
the procedure guards against autocorrelation of any order up to {it:bglags} —
not just at the highest lag. This is more comprehensive than testing only at a
single lag order. For the {bf:lagsel(aic)} and {bf:lagsel(bic)} options, a
post-selection Breusch-Godfrey test is automatically performed and a warning is
issued if autocorrelation remains, alerting the user to consider {bf:lagsel(bg)}
instead.

{pstd}
{ul:Choosing the model specification}

{pstd}
Model C (both DU and DT, the default) is the most general and is recommended
when there is uncertainty about the nature of the breaks. If economic theory
suggests that breaks affect only the level of the series (e.g. a one-time
policy intervention), Model A may be more appropriate. Model B is suitable
when breaks are expected to alter the growth rate. Note that using a more
general model than necessary reduces the power of the test.

{pstd}
{ul:Choosing the number of breaks}

{pstd}
The maximum number of breaks (up to 5) should reflect prior economic knowledge
about the series. Kapetanios (2005) shows that power generally decreases with
{it:m} because successive breaks bring the alternative hypothesis closer to
the null. Setting {it:m} unnecessarily large weakens the ability to reject
the unit root null. For most macroeconomic series, {it:m} = 3 to 5 is
a reasonable range.

{pstd}
{ul:Choosing the lag selection method}

{pstd}
The default {bf:ttest} method replicates the original implementation of
Kapetanios (2005). The {bf:bg} method is recommended when serial correlation
in residuals is a concern, as it directly targets its elimination using a
formal statistical test. The {bf:aic} and {bf:bic} methods are theoretically
justified by Ng and Perron (1995) and Kapetanios (2005), but since they
minimise an information criterion rather than testing for autocorrelation,
they may select a lag length that leaves residual serial correlation. The
automatic BG post-check alerts users to this possibility.

{pstd}
{ul:Trimming parameter}

{pstd}
The default trimming epsilon = 0.1 excludes break dates in the first and last
10% of the sample. A smaller epsilon allows breaks closer to the sample
boundaries but may worsen finite sample properties. The procedure automatically
adjusts epsilon if the chosen value does not allow for any breaks.

{pstd}
{ul:Sample size considerations}

{pstd}
Table IV of Kapetanios (2005) shows that when k is determined by sequential
testing, there is considerable size distortion in small samples (T = 50),
but the test performs well for T >= 100. Users should exercise caution when
applying the test to small samples.

{pstd}
{ul:Computational note}

{pstd}
{cmd:kapetanios} uses Stata's Mata matrix language for all inner computations,
providing substantially faster execution than a pure ado-file implementation.
All matrix operations — including OLS estimation, lag selection, and break
search — are performed in Mata.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:kapetanios} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}Kapetanios test statistic (minimum t-statistic){p_end}
{synopt:{cmd:r(cv10)}}critical value at 10% significance level{p_end}
{synopt:{cmd:r(cv05)}}critical value at 5% significance level{p_end}
{synopt:{cmd:r(cv01)}}critical value at 1% significance level{p_end}
{synopt:{cmd:r(breaks)}}number of breaks found{p_end}
{synopt:{cmd:r(best_lag)}}lag length selected{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(lambda)}}column vector of estimated break observation numbers{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}
Open dataset, declare time series and run with default settings:{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. kapetanios consump}{p_end}

{pstd}
Maximum 2 breaks, intercept breaks only (Model A):{p_end}
{phang2}{cmd:. kapetanios consump, breaks(2) model(1)}{p_end}

{pstd}
Trend breaks only (Model B), with kmax = 4:{p_end}
{phang2}{cmd:. kapetanios consump, breaks(2) kmax(4) model(2)}{p_end}

{pstd}
Replication of Kapetanios (2005) specification — kmax = 1:{p_end}
{phang2}{cmd:. kapetanios consump, breaks(3) kmax(1) epsilon(0.1) model(3)}{p_end}

{pstd}
Both intercept and trend breaks (Model C), default specification:{p_end}
{phang2}{cmd:. kapetanios consump, model(3)}{p_end}

{pstd}
Breusch-Godfrey based lag selection (recommended):{p_end}
{phang2}{cmd:. kapetanios consump, lagsel(bg)}{p_end}

{pstd}
BG lag selection with manual horizon of 8 lags:{p_end}
{phang2}{cmd:. kapetanios consump, lagsel(bg) bglags(8)}{p_end}

{pstd}
AIC-based lag selection:{p_end}
{phang2}{cmd:. kapetanios consump, lagsel(aic)}{p_end}

{pstd}
BIC-based lag selection:{p_end}
{phang2}{cmd:. kapetanios consump, lagsel(bic)}{p_end}

{pstd}
Replication of Gretl Kapetanios package v2.1 results:{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. kapetanios consump, breaks(3) kmax(1) epsilon(0.1) model(3)}{p_end}
{pstd}
This produces identical results to {bf:Kapetanios(consump, 3, 1, 0.1, 3)}
in Gretl's Kapetanios package (version 2.1, 2022-04-11).{p_end}

{pstd}
Access stored results after the test:{p_end}
{phang2}{cmd:. kapetanios consump, breaks(2)}{p_end}
{phang2}{cmd:. display r(stat)}{p_end}
{phang2}{cmd:. matrix list r(lambda)}{p_end}

{pstd}
{ul:Examples using Gretl sample datasets}

{pstd}
The following examples use datasets from the Gretl sample file collection,
hosted at {browse "https://www.eruygurakademi.com/datasets/kapetanios/":https://www.eruygurakademi.com/datasets/kapetanios/}.
Results have been verified to be numerically identical to the Gretl implementation.

{pstd}
{bf:Annual data} (T=43): Interest rates and inflation, Canada.
Note: the Gretl implementation returns a non-invertible matrix error and
terminates for this dataset; {cmd:kapetanios} completes the estimation successfully,
demonstrating improved numerical stability.{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/jgm-data.dta, clear}{p_end}
{phang2}{cmd:. kapetanios r_s, kmax(5) breaks(4)}{p_end}

{pstd}
{bf:Quarterly data} (T=258): MIDAS data, quarterly GDP and monthly covariates.{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/gdp_midas.dta, clear}{p_end}
{phang2}{cmd:. kapetanios qgdp, kmax(3) breaks(5)}{p_end}
{phang2}{cmd:. kapetanios d.qgdp, kmax(3) breaks(5)}{p_end}
{phang2}{cmd:. kapetanios d2.qgdp, kmax(3) breaks(5)}{p_end}

{pstd}
{bf:Monthly data} (T=144): Box and Jenkins Series G (airline passengers).{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/bjg.dta, clear}{p_end}
{phang2}{cmd:. kapetanios lg, kmax(3) breaks(5)}{p_end}
{phang2}{cmd:. kapetanios d.lg, kmax(3) breaks(5)}{p_end}

{pstd}
{bf:Weekly data} (T=2117): Weekly NYSE closing price, 1966–2006.
Note: due to the large sample size, estimation may take approximately 2 minutes.{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/nysewk.dta, clear}{p_end}
{phang2}{cmd:. kapetanios close, kmax(1) breaks(5)}{p_end}
{phang2}{cmd:. kapetanios d.close, kmax(1) breaks(5)}{p_end}

{pstd}
{bf:Daily data} (T=1974): Bollerslev and Ghysels exchange rate data.
Note: due to the large sample size, estimation may take approximately 2 minutes.{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/b-g.dta, clear}{p_end}
{phang2}{cmd:. kapetanios Y, kmax(1)}{p_end}
{phang2}{cmd:. kapetanios Y, kmax(3) breaks(5)}{p_end}
{phang2}{cmd:. kapetanios d.Y, kmax(3) breaks(5)}{p_end}


{marker references}{...}
{title:References}

{phang}
Bai, J. and Perron, P. (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica}, 66(1), 47–78.

{phang}
Sánchez Urbina, A. E., Ramírez, R. and Ventosa-Santaulària, D. (2022).
Kapetanios (Gretl package, version 2.1).
Available from the Gretl package repository: {browse "http://gretl.sourceforge.net":http://gretl.sourceforge.net}

{phang}
Kapetanios, G. (2005). Unit-root testing against the alternative hypothesis
of up to m structural breaks. {it:Journal of Time Series Analysis}, 26(1), 123–133.

{phang}
Lumsdaine, R. L. and Papell, D. H. (1997). Multiple trend breaks and the
unit root hypothesis. {it:Review of Economics and Statistics}, 79(2), 212–217.

{phang}
Ng, S. and Perron, P. (1995). Unit root tests in ARMA models with
data-dependent methods for the selection of the truncation lag.
{it:Journal of the American Statistical Association}, 90(429), 268–281.

{phang}
Schwert, G. W. (1989). Tests for unit roots: A Monte Carlo investigation.
{it:Journal of Business & Economic Statistics}, 7(2), 147–159.

{phang}
Zivot, E. and Andrews, D. W. K. (1992). Further evidence on the Great Crash,
the oil-price shock, and the unit-root hypothesis.
{it:Journal of Business & Economic Statistics}, 10(3), 251–270.


{marker author}{...}
{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pmore}
kapetanios v3.2.0 — April 2026

{pstd}
{ul:Please cite as:}

{phang}
Eruygur, H. O. 2026. {bf:kapetanios}: Kapetanios (2005) unit-root test with up to 5 structural breaks.
Stata package version 3.2.0. Available from: {browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}
