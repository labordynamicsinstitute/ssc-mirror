{smcl}
{* *! version 2.0.0  25jun2026}{...}
{viewerjumpto "Syntax" "hatemicoint##syntax"}{...}
{viewerjumpto "Description" "hatemicoint##description"}{...}
{viewerjumpto "Options" "hatemicoint##options"}{...}
{viewerjumpto "Remarks" "hatemicoint##remarks"}{...}
{viewerjumpto "Examples" "hatemicoint##examples"}{...}
{viewerjumpto "Stored results" "hatemicoint##results"}{...}
{viewerjumpto "References" "hatemicoint##references"}{...}
{viewerjumpto "Author" "hatemicoint##author"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:hatemicoint} {hline 2}}Tests for cointegration with two unknown regime shifts{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:hatemicoint} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt maxl:ags(#)}}maximum number of lags for ADF test; default is {cmd:maxlags(8)}{p_end}
{synopt:{opt lags:election(string)}}lag selection criterion: {cmd:aic}, {cmd:sic}, or {cmd:tstat}; default is {cmd:tstat}{p_end}
{synopt:{opt kernel(string)}}kernel for long-run variance: {cmd:iid}, {cmd:bartlett}, or {cmd:qs}; default is {cmd:iid}{p_end}
{synopt:{opt bwl(#)}}bandwidth for long-run variance; default is round(4*(T/100)^(2/9)){p_end}
{synopt:{opt trim:ming(#)}}trimming rate for break search; default is {cmd:trimming(0.15)}{p_end}
{synopt:{opt model(#)}}model specification: {cmd:1} (level shift), {cmd:2} (level shift with trend), or {cmd:3} (regime shift); default is {cmd:model(3)}{p_end}
{syntab:Reporting}
{synopt:{opt graph}}produce a combined figure: the series and the cointegrating residual with the estimated breaks, plus a decision plot{p_end}
{synopt:{opt grapht:est(test)}}which test's breaks to display in the series/residual panels: {cmd:adf}, {cmd:zt}, or {cmd:za}; default is {cmd:zt} (implies {cmd:graph}){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:hatemicoint}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:hatemicoint} implements three residual-based tests for cointegration in the presence of two unknown
structural breaks, as developed by Hatemi-J (2008). The timing of the breaks is determined endogenously by
searching over all admissible pairs of break points within a trimmed range. Three deterministic specifications
are supported (see {cmd:model()}): a level shift, a level shift with trend, and a regime shift that allows the
slope coefficients to change as well.

{pstd}
The Mata engine reproduces the original GAUSS reference implementation (the {cmd:coint_hatemiJ} routine of the
TSPDLIB library and Hatemi-J's own code) to within machine precision for the ADF*, Zt* and Za* statistics.

{pstd}
The command tests the null hypothesis of no cointegration against the alternative of cointegration with two regime shifts.
It reports three test statistics:

{phang}
{bf:ADF*}: Augmented Dickey-Fuller test on residuals with two regime shifts{p_end}

{phang}
{bf:Zt*}: Phillips-Perron Zt test on residuals with two regime shifts{p_end}

{phang}
{bf:Za*}: Phillips-Perron Za (Zalpha) test on residuals with two regime shifts{p_end}

{pstd}
All three tests search for the break points that provide the strongest evidence against the null hypothesis
(i.e., the most negative test statistics). The critical values are based on response surface analysis
and Monte Carlo simulations as reported in Hatemi-J (2008).

{pstd}
The cointegrating regression depends on {cmd:model()}. With D{subscript:1t} and D{subscript:2t} equal to 1 after
the first and second break points, respectively:

{p 8 12 2}
{cmd:model(1)} (level shift):{break}
y{subscript:t} = α{subscript:0} + α{subscript:1}D{subscript:1t} + α{subscript:2}D{subscript:2t} + β'x{subscript:t} + u{subscript:t}

{p 8 12 2}
{cmd:model(2)} (level shift with trend):{break}
y{subscript:t} = α{subscript:0} + α{subscript:1}D{subscript:1t} + α{subscript:2}D{subscript:2t} + γt + β'x{subscript:t} + u{subscript:t}

{p 8 12 2}
{cmd:model(3)} (regime shift, default):{break}
y{subscript:t} = α{subscript:0} + α{subscript:1}D{subscript:1t} + α{subscript:2}D{subscript:2t} + β'{subscript:0}x{subscript:t} + β'{subscript:1}D{subscript:1t}x{subscript:t} + β'{subscript:2}D{subscript:2t}x{subscript:t} + u{subscript:t}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt maxlags(#)} specifies the maximum number of lags to consider in the ADF test regression.
The default is 8. A higher value allows for more flexible dynamics but may reduce power in small samples.

{phang}
{opt lagselection(string)} specifies the criterion for selecting the optimal number of lags in the ADF test.
Options are:

{phang2}
{cmd:aic} - Akaike Information Criterion

{phang2}
{cmd:sic} - Schwarz Information Criterion (also known as BIC)

{phang2}
{cmd:tstat} - t-statistic significance approach (default). This method starts with {cmd:maxlags} and
sequentially tests whether the coefficient on the last lag is significant, reducing the lag order
until a significant coefficient is found or zero lags is reached.

{phang}
{opt kernel(string)} specifies the kernel function for computing the long-run variance in the Phillips-Perron tests.
Options are:

{phang2}
{cmd:iid} - No long-run variance correction (assumes i.i.d. errors; default)

{phang2}
{cmd:bartlett} - Bartlett kernel

{phang2}
{cmd:qs} (or {cmd:quadraticspectral}) - Quadratic spectral kernel

{phang}
{opt bwl(#)} specifies the bandwidth for the long-run variance estimation.
The default is round(4*(T/100)^(2/9)) following Andrews (1991).
This option is only used when {cmd:kernel} is {cmd:bartlett} or {cmd:qs}.

{phang}
{opt trimming(#)} specifies the trimming proportion for the break search.
The default is 0.15, meaning that breaks are searched for in the range [0.15T, 0.85T]
and the two breaks must be at least 0.15T observations apart. This follows the approach
of Gregory and Hansen (1996). The value must be between 0 and 0.5.

{phang}
{opt model(#)} specifies the deterministic specification of the cointegrating regression:

{phang2}
{cmd:1} - level shift: breaks in the intercept only.

{phang2}
{cmd:2} - level shift with trend: breaks in the intercept, plus a linear time trend.

{phang2}
{cmd:3} - regime shift (default): breaks in both the intercept and the slope coefficients on {it:indepvars}.

{dlgtab:Reporting}

{phang}
{opt graph} produces a combined figure (named {cmd:hatemicoint}) with three panels:
(i) the dependent variable over time with the three regimes shaded and the two estimated break
dates marked; (ii) the cointegrating residual to which the unit-root tests are applied, with the
same break lines; and (iii) a decision plot in which each statistic is divided by its 5% critical
value, so that a single reference line at 1.0 separates rejection (marker to the right, shown in
green) from non-rejection (marker to the left, shown in red). Grey ticks mark the 1% and 10%
critical-value ratios.

{phang}
{opt graphtest(test)} selects which test's estimated break dates are drawn in the series and
residual panels: {cmd:adf}, {cmd:zt} (default), or {cmd:za}. Specifying {opt graphtest()} implies
{opt graph}. The decision panel always shows all three statistics.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:hatemicoint} extends the Gregory and Hansen (1996) cointegration test to allow for two regime shifts
instead of one. The test is appropriate when:

{phang}
1. You suspect two structural breaks in the cointegrating relationship.

{phang}
2. The timing of the breaks is unknown a priori.

{phang}
3. You want to test for cointegration while accounting for these breaks.

{pstd}
The test works by:

{phang}
1. Estimating the cointegrating regression for all possible combinations of two break points
(subject to the trimming constraint).

{phang}
2. Computing the test statistic for each combination.

{phang}
3. Selecting the minimum (most negative) test statistic as the test value.

{phang}
4. Comparing this value to critical values that account for the search process.

{pstd}
{bf:Critical values} are available for models with 1 to 4 independent variables (k = 1, 2, 3, 4).
These values were generated via simulation methods and are reported at the 1%, 5%, and 10% significance levels.
For k > 4, the command will produce an error as critical values are not available.

{pstd}
{bf:Interpretation}: The null hypothesis is no cointegration. More negative values of the test statistics
provide stronger evidence against the null. If the test statistic is more negative than the critical value,
reject the null and conclude there is cointegration with regime shifts.

{pstd}
{bf:Computational note}: The command searches over all valid break combinations, which can be computationally
intensive for large datasets. With default trimming of 0.15, approximately (0.55T)*(0.7T)/2 regressions
are estimated, which could be substantial for large T.

{pstd}
{bf:Panel data}: This test is designed for single time series only. Panel data is not supported.
If you have panel data, use {helpb xtset} and analyze each panel separately or use
panel cointegration tests such as {helpb xtcointtest}.

{pstd}
{bf:Sample size}: The test requires a reasonably large sample size. With default trimming of 0.15,
you need at least T > 20 observations to have valid break search regions. Larger samples provide
more reliable inference.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Basic test with default options{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc}{p_end}

{pstd}Specify maximum lags and use AIC for lag selection{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, maxlags(12) lagselection(aic)}{p_end}

{pstd}Use quadratic spectral kernel and custom bandwidth{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, kernel(qs) bwl(8)}{p_end}

{pstd}Level shift only (model 1) and level shift with trend (model 2){p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, model(1)}{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, model(2)}{p_end}

{pstd}Produce the break-and-decision figure{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, graph}{p_end}

{pstd}Draw the breaks selected by the Za* test{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, graphtest(za)}{p_end}

{pstd}Use more conservative trimming{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc, trimming(0.20)}{p_end}

{pstd}Test with multiple regressors{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc ln_consump}{p_end}

{pstd}Access stored results{p_end}
{phang2}{cmd:. hatemicoint ln_inv ln_inc}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. display "ADF test statistic: " r(adf_min)}{p_end}
{phang2}{cmd:. display "First break at observation: " r(tb1_adf)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:hatemicoint} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(adf_min)}}minimum ADF* test statistic{p_end}
{synopt:{cmd:r(lag_adf)}}selected ADF lag order at the ADF* break{p_end}
{synopt:{cmd:r(tb1_adf)}}first break for ADF* test (observation number){p_end}
{synopt:{cmd:r(tb2_adf)}}second break for ADF* test (observation number){p_end}
{synopt:{cmd:r(date1_adf)}}first break for ADF* test (time-variable value){p_end}
{synopt:{cmd:r(date2_adf)}}second break for ADF* test (time-variable value){p_end}
{synopt:{cmd:r(zt_min)}}minimum Zt* test statistic{p_end}
{synopt:{cmd:r(tb1_zt)}}first break for Zt* test (observation number){p_end}
{synopt:{cmd:r(tb2_zt)}}second break for Zt* test (observation number){p_end}
{synopt:{cmd:r(date1_zt)}}first break for Zt* test (time-variable value){p_end}
{synopt:{cmd:r(date2_zt)}}second break for Zt* test (time-variable value){p_end}
{synopt:{cmd:r(za_min)}}minimum Za* test statistic{p_end}
{synopt:{cmd:r(tb1_za)}}first break for Za* test (observation number){p_end}
{synopt:{cmd:r(tb2_za)}}second break for Za* test (observation number){p_end}
{synopt:{cmd:r(date1_za)}}first break for Za* test (time-variable value){p_end}
{synopt:{cmd:r(date2_za)}}second break for Za* test (time-variable value){p_end}
{synopt:{cmd:r(nobs)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of independent variables{p_end}
{synopt:{cmd:r(model)}}model specification (1, 2, or 3){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(cv_adfzt)}}1x3 matrix of critical values for ADF and Zt tests (1%, 5%, 10%){p_end}
{synopt:{cmd:r(cv_za)}}1x3 matrix of critical values for Za test (1%, 5%, 10%){p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance matrix estimation.
{it:Econometrica} 59: 817-858.

{phang}
Engle, R. F., and C. W. J. Granger. 1987. Cointegration and error correction: Representation,
estimation and testing. {it:Econometrica} 55: 251-276.

{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in models with regime shifts.
{it:Journal of Econometrics} 70: 99-126.

{phang}
Hatemi-J, A. 2008. Tests for cointegration with two unknown regime shifts with an application
to financial market integration. {it:Empirical Economics} 35: 497-505.

{phang}
Phillips, P. C. B. 1987. Time series regression with a unit root.
{it:Econometrica} 55: 277-301.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan ROUDANE{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}


{title:Also see}

{psee}
Online: {helpb dfuller}, {helpb pperron}, {helpb vecrank}, {helpb xtcointtest}
{p_end}
