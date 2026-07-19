{smcl}
{* *! version 1.3.0  09jul2026  Ozan Eruygur}{...}
{hline}
help for {hi:kperrony}{right:version 1.3.0}
{hline}

{title:Title}

{p 4 8 2}{hi:kperrony} {hline 2} Determining the number & dates of structural breaks in
cointegrated equations, with regime-wise estimates and stability tests
(Kejriwal & Perron, 2010; Kejriwal, Perron & Yu, 2021){p_end}

{title:Syntax}

{p 8 16 2}{cmd:kperrony} {it:depvar} {it:zvarlist} {ifin} [{cmd:,} {it:options}]{p_end}

{p 4 8 2}where {it:depvar} is the dependent I(1) variable and {it:zvarlist} contains the I(1)
regressors. Time-series operators are allowed. The data must be {cmd:tsset} (a single time
series, no gaps in the estimation sample).{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt xz:ero(varlist)}}I(0) regressors; default is none{p_end}
{synopt:{opt lag:s(#)}}number of leads and lags of the first-differenced I(1) regressors for
the DOLS endogeneity correction; default is {cmd:lags(4)}{p_end}
{synopt:{opt tr:end}}use critical values for trending regressors{p_end}
{synopt:{opt nodols}}estimate the static regression without the DOLS leads-and-lags
correction{p_end}
{synopt:{opt nosc}}do not apply the serial correlation correction in the branch with I(0)
regressors (sets robust=0 in the original code){p_end}
{synopt:{opt lev:el(#)}}confidence level for all critical values: 90, 95, 97.5, or 99; default
is {cmd:level(95)}{p_end}
{synopt:{opt notwo:step}}suppress the Kejriwal-Perron-Yu (2021) second-step stability
tests{p_end}
{synopt:{opt noak:test}}skip the Arai-Kurozumi (2007) cointegration test{p_end}
{synopt:{opt akrep:s(#)}}replications for the simulated Arai-Kurozumi critical value;
default is {cmd:akreps(10000)} as in the authors' code{p_end}
{synopt:{opt seed(#)}}set the random-number seed before the simulation, for
run-to-run reproducibility of the simulated critical value{p_end}
{synopt:{opt full:precision}}display all test statistics at full (%21.0g) precision; full
double precision is always available in the stored r() matrices{p_end}
{synoptline}

{title:Description}

{p 4 4 2}The tests of Bai and Perron (1998, 2003) are the standard tools for detecting
multiple structural breaks in a linear regression: they test whether the regression
coefficients change over the sample, determine how many breaks are present, and estimate the
break dates. The Bai-Perron tests are designed for stationary regressions: the dependent
variable and the regressors are I(0) and the errors are weakly dependent. Kejriwal and Perron
(2010) and Kejriwal, Perron & Yu (2021) carry the same testing architecture over to
cointegrated regressions, in which the dependent variable and the regressors are I(1),
optionally together with I(0) regressors, and the errors are I(0).{p_end}

{p 4 4 2}{cmd:kperrony} answers three questions about a cointegrating regression: (1) are its
coefficients stable over the sample, (2) if not, how many structural breaks are there and when
do they occur, and (3) which individual coefficients actually change. It implements the
sup-Wald tests of Kejriwal and Perron (2010, henceforth KP) for multiple structural changes in
single-equation cointegrated regression models, together with the two-step procedure of
Kejriwal, Perron, and Yu (2021, henceforth KPY) for testing partial parameter stability.{p_end}

{p 4 4 2}A leading use of these tests is as the first stage of a cointegration analysis with
structural breaks. Cointegration tests that allow for regime shifts (for example Arai and
Kurozumi 2007 and its multiple-break extension in Kejriwal 2008, or residual-based tests with
level and regime shifts) require the practitioner to specify how many breaks to allow, and
estimation of a broken long-run relationship requires the break dates. Rather than fixing these
quantities arbitrarily, the KP statistics provide a formal, data-based answer: the UDmax test
establishes whether any break is present at all, the sequential SEQ(k+1|k) procedure selects
the number of breaks, and the break dates are estimated consistently by global minimization of
the sum of squared residuals using the dynamic programming algorithm of Bai and Perron (1998,
2003). The KP statistics test the stability of the coefficients of a cointegrating
relationship; because they are also consistent against a purely spurious regression, KPY
recommend complementing a rejection with a test of the null of cointegration with breaks, such
as Arai and Kurozumi (2007) or Kejriwal (2008), applied with the number of breaks selected
here.{p_end}

{p 4 4 2}The model is a linear cointegrating regression with m breaks (m+1 regimes) in which
the dependent I(1) variable is explained by an intercept, I(1) regressors, and optionally I(0)
regressors ({opt xzero()}), allowing serial correlation and conditional heteroskedasticity in
the errors. KP distinguish pure structural change models, in which all coefficients including
the intercept change across regimes, from partial structural change models in which only a
subset changes. {cmd:kperrony} computes the pure structural change statistics: supF(k) against
a fixed number of breaks k = 1,...,5 and the double-maximum statistic UDmax for an unknown
number of breaks up to 5, with trimming 0.15. The limit distributions are pivotal and the
critical values are those tabulated by KP for nontrending and trending ({opt trend})
data.{p_end}

{p 4 4 2}Endogeneity of the I(1) regressors is handled by dynamic OLS (Saikkonen 1991),
augmenting the regression with {opt lags(#)} leads and lags of the first-differenced I(1)
regressors (on the choice of the number of leads and lags see Kejriwal and Perron 2008). Serial
correlation is handled through a hybrid nonparametric estimate of the long-run variance with
the quadratic spectral kernel: the autocovariances are computed from the residuals under the
null hypothesis, which ensures an adequately sized test, while the data-dependent bandwidth of
Andrews (1991) is computed from the residuals under the alternative, which bypasses the
non-monotonic power problem that affects Lagrange multiplier type tests (see KP for
details).{p_end}

{p 4 4 2}The reason for the second step is Theorem 1 of KPY: in cointegrated regressions,
unlike the stationary framework of Bai and Perron (1998), the partial structural change
statistics of KP diverge with the sample size when any coefficient outside the tested subset is
unstable, so their asymptotic size is 100 percent and a rejection cannot be attributed to the
coefficients under test. The two-step remedy is: (1) test the joint stability of all
coefficients with the pure structural change statistics; (2) upon a rejection, test the
stability of each coefficient of interest with an F test using chi-squared critical values
(degrees of freedom equal to the number of breaks), allowing all remaining coefficients to
change at the break dates estimated in the first step. The procedure has asymptotic size no
larger than the nominal level of each step (KPY, Corollary 1) and is conservative when no
coefficient breaks. {cmd:kperrony} runs the second step automatically for every regression
coefficient whenever breaks are detected.{p_end}

{p 4 4 2}Reported break dates refer to the {it:last observation of each regime} and are
displayed using the {cmd:tsset} calendar format; the break dates implied by each candidate
number of breaks k = 1,...,5 are also reported below the supF table.{p_end}

{p 4 4 2}
The output is organized in numbered tables: [1] the supF(k) and UDmax tests with
significance stars and a decision line, [2] the sequential SEQ(k+1|k) procedure
with its selection decision, [3] the estimated break dates and regime-wise
coefficient estimates with HAC standard errors and confidence intervals, and
[4] the Kejriwal-Perron-Yu (2021) two-step partial stability
tests with a summary of which coefficients are found unstable, and [5] the
Arai-Kurozumi (2007) test of the null of cointegration computed at the estimated
breaks, with a critical value simulated from its asymptotic distribution at the
estimated break fractions; a rejection warns that the regime-wise regression may
be spurious. Stars mark the
strongest tabulated level (10, 5, 2.5 or 1 percent) at which a statistic rejects;
the decision lines use the level set by {opt level(#)}.

{title:Relation to the Bai-Perron (1998, 2003) tests}

{p 4 4 2}The Bai-Perron tests are designed for stationary regressions: the dependent variable
and the regressors are I(0) and the errors are weakly dependent. The limit distributions of
their sup-F, UDmax, and SEQ(l+1|l) statistics, and hence their critical value tables, are
derived under that stationary framework. Kejriwal and Perron (2010) carry the same testing
architecture over to cointegrated regressions, in which the dependent variable and the
regressors are I(1), optionally together with I(0) regressors, and the errors are I(0). With
integrated regressors the limit distributions of the Wald statistics change -
they involve
functionals of Brownian motions driven by the stochastic trends - so applying the Bai-Perron
critical values to a cointegrating regression is invalid. {cmd:kperrony} uses the critical
values tabulated by KP for the cointegrated framework, not those of Bai and Perron.{p_end}

{p 4 4 2}Beyond the critical values, the cointegrated setting requires two adjustments with no
counterpart in the stationary framework: the endogeneity of the I(1) regressors is handled by
the DOLS leads and lags, and the long-run variance is estimated by the hybrid method described
above. The break dates themselves are still located by the Bai-Perron dynamic programming
algorithm minimizing the global sum of squared residuals; the two frameworks share this
computational engine. Finally, in the stationary Bai-Perron framework, tests of partial
parameter stability remain asymptotically valid in the presence of breaks in the coefficients
not under test; in the cointegrated framework this invariance breaks down (KPY, Theorem 1),
which is precisely why the second step of KPY is needed before instability can be attributed to
specific coefficients.{p_end}

{title:Checking the I(1) premise}

{p 4 4 2}
The Kejriwal-Perron framework presupposes that the regressors are I(1) and the
errors are I(0) throughout the sample, so that the equation is a cointegrating
regression in every regime. Two practical checks are recommended before running
{cmd:kperrony}:

{p 8 12 2}- unit root tests on each series over the full sample (for example
{help dfuller} or, allowing for structural breaks, the author's {help ckptest},
{help kapetanios}, {help narayanp}, or {help leestra}, if installed);{p_end}
{p 8 12 2}- a test for shifts in the persistence of each series: if the order of
integration of a regressor itself changes within the sample (from I(1) to I(0) or
the reverse), the premise fails. The companion package {cmd:kypshift}
(Kejriwal-Yu-Perron 2020, available from SSC) tests precisely this, reporting the
number and dates of persistence breaks with wild bootstrap p-values.{p_end}

{p 4 4 2}
The output of {cmd:kperrony} ends with a reminder of this premise. The two
packages are complementary: {cmd:kypshift} asks whether the persistence of each
series is stable; {cmd:kperrony} asks whether the coefficients of the
cointegrating equation linking them are stable.

{title:Choosing the options}

{p 4 4 2}{bf:Endogeneity: {opt lags(#)} versus {opt nodols}.} In the framework of KP and
KPY, endogeneity means that the long-run covariance between the regression error and the
innovations of the I(1) regressors is nonzero: in Assumption A1 of KPY these covariances are
the off-diagonal blocks of the long-run covariance matrix Omega, and strict exogeneity is the
special case in which those blocks are zero. KPY derive their Theorem 1 under strict
exogeneity and state explicitly that the assumption is imposed only to simplify the analysis:
endogenous I(1) regressors are accounted for by the dynamic OLS estimator, which augments the
regression with leads and lags of the first-differenced I(1) regressors (Saikkonen 1991), the
number of leads and lags being selectable by the information criteria of Kejriwal and Perron
(2008). Their own empirical application applies this correction by default, with four leads
and lags on quarterly data. Economic time series are typically determined jointly, so there is
in general no reason for the equation error to be orthogonal to the regressor innovations at
every lead and lag; the correction literature for cointegrating regressions - fully modified
OLS (Phillips and Hansen 1990), dynamic OLS (Saikkonen 1991), canonical cointegrating
regressions (Park 1992) - exists because the limit distribution of the static OLS estimator
carries nuisance terms whenever these long-run covariances are nonzero. Keep the default DOLS
correction accordingly. Use {opt nodols} only when the regressors can be treated as strictly
exogenous - for example in simulation exercises where the data generating process imposes it -
or when a static specification is to be replicated; {opt nodols} also avoids the loss of
2 x {it:lags} + 1 effective observations.{p_end}

{p 4 4 2}{bf:Number of leads and lags: {opt lags(#)}.} The default {cmd:lags(4)} follows the
empirical application of KPY (2021) on quarterly data. The number can also be chosen with the
data-dependent rules of Kejriwal and Perron (2008). A larger value absorbs more of the
endogeneity but costs 2 x {it:lags} + 1 effective observations and adds (2 x {it:lags} + 1)
columns per I(1) regressor to every regression, which matters in small samples.{p_end}

{p 4 4 2}{bf:Serial correlation: {opt nosc}.} The errors of a cointegrating regression are
typically serially correlated, and the default correction should be kept: in the branch
without I(0) regressors the statistics are scaled by the hybrid long-run variance described
above, and in the branch with I(0) regressors ({opt xzero()}) a heteroskedasticity and
autocorrelation consistent covariance matrix is used. {opt nosc} switches the latter branch to
a covariance estimator that allows heteroskedasticity across regimes but no serial
correlation; use it only when the errors are known to be serially uncorrelated or to replicate
results computed that way. {opt nosc} has no effect when there are no I(0) regressors.{p_end}

{p 4 4 2}{bf:Trending regressors: {opt trend}.} KP tabulate separate critical values for
nontrending and trending variables. If the I(1) variables drift over the sample (random walks
with drift, visibly trending series), specify {opt trend} so that the trending critical values
are used; otherwise keep the default nontrending values. The test statistics themselves are
identical under both settings; only the critical values change.{p_end}

{p 4 4 2}{bf:Significance level: {opt level(#)}.} All critical values (supF, UDmax, SEQ, and
the chi-squared second step) are taken at the chosen level; the sequential procedure therefore
selects the number of breaks at that level.{p_end}

{title:Remarks on the port}

{p 4 4 2}1. {cmd:kperrony} is a direct port of the MATLAB code accompanying KPY (2021) (written
by Xuewen Yu, June 2021), which embeds the Bai-Perron dynamic programming engine. The port
reproduces the published code, including the following behavior verified in the original: (a)
in the branch without I(0) regressors, the long-run variance entering the supF statistics uses
the residuals from the alternative model for both the bandwidth and the autocovariances,
whereas the sequential SEQ tests use the hybrid estimate combining null and alternative
residuals; (b) the small-sample degrees-of-freedom scaling applied in the branch with I(0)
regressors is not applied in the branch without them. These choices follow the authors' code as
published.{p_end}

{p 4 4 2}2. Calendar dates in KPY (2021, Table IV) are shifted by one quarter relative to the
actual observation dates because of the year/quarter conversion used by the authors (for
example, the single break of the unrestricted log-log model at observation 138 corresponds to
1993q2, printed as 1993:Q3 in the paper). {cmd:kperrony} reports the exact {cmd:tsset} date of
the break observation.{p_end}

{p 4 4 2}3. The regime-wise coefficient estimates reported by {cmd:kperrony} are the OLS
estimates of the pure structural change (DOLS) regression evaluated at the estimated break
dates. The point estimates in Table IV of KPY were produced by a separate estimation and
bootstrap program and may differ slightly.{p_end}

{title:Examples}

{p 4 4 2}{bf:Example 1: US money demand (Kejriwal, Perron & Yu 2021, Section 5).} The first
command reproduces the unrestricted log-log results of KPY Table III, Panel A (UDmax = 423.03,
one break in 1993, second-step statistics 6.86, 7.03, 5.02); the second the restricted log-log
form of Panel B (supF(1) = 613.14, two breaks); table [3] reproduces the regime-wise
estimates of KPY Table 4 with their HAC standard errors (for example, a first-regime
income elasticity of 0.5564 with standard error 0.0441 in the unrestricted log-log
form); table [5] reports the Arai-Kurozumi statistics 0.0562, 0.0895, 0.0620 and
0.0684 for the four specifications, none of which rejects cointegration; the last
two commands run the unrestricted and restricted
semi-log forms. The dataset is in double precision, already {cmd:tsset} (quarterly,
{cmd:qdate}), and contains the levels {cmd:MdP}, {cmd:YdP}, {cmd:r}, {cmd:m} and their
logarithms {cmd:ly}, {cmd:lydp}, {cmd:lr}, {cmd:lm}.{p_end}

{phang2}{cmd:. use "https://eruygurakademi.com/datasets/kperrony/moneydemand.dta", clear}{p_end}
{phang2}{cmd:. kperrony ly lydp lr, lags(4)}{p_end}
{phang2}{cmd:. kperrony lm lr, lags(4)}{p_end}
{phang2}{cmd:. kperrony ly lydp r, lags(4)}{p_end}
{phang2}{cmd:. kperrony lm r, lags(4)}{p_end}

{p 4 4 2}To display the test statistics at full precision (as used in the validation
below):{p_end}

{phang2}{cmd:. kperrony ly lydp lr, lags(4) fullprecision}{p_end}

{p 4 4 2}{bf:Example 2: reading the Arai-Kurozumi diagnostic.} The statistic in table [5]
is deterministic; only its critical value is simulated, so {opt seed(#)} makes the
displayed critical value reproducible across runs. In the unrestricted log-log form
the statistic is 0.0562, well below its simulated 5 percent critical value: the
null of cointegration with the estimated break is not rejected, and the regime-wise
results of tables [1]-[4] rest on solid ground.{p_end}

{phang2}{cmd:. kperrony ly lydp lr, lags(4) seed(2026)}{p_end}
{phang2}{cmd:. display r(ak), r(akcv)}{p_end}

{p 4 4 2}{bf:Example 3: a rejection, and why table [5] matters.} Regressing log real
income on the log interest rate produces a seemingly ordinary output: the sequential
procedure reports one break with regime-wise estimates. But the Arai-Kurozumi
statistic is 0.1797, above its simulated 5 percent critical value: the null of
cointegration is rejected, so the equation is likely a spurious regression between
two integrated series, the reported break notwithstanding. Structural change tests
applied to a non-cointegrated equation will often "find" breaks; table [5] is the
guard against reading such output as evidence of a breaking cointegrating
relation.{p_end}

{phang2}{cmd:. kperrony lydp lr, lags(4) seed(2026)}{p_end}

{p 4 4 2}{bf:Example 4: synthetic data with three I(1) regressors and two breaks.} DOLS,
trending critical values, and the static regression without the DOLS correction.{p_end}

{phang2}{cmd:. use "https://eruygurakademi.com/datasets/kperrony/synth_q3.dta", clear}{p_end}
{phang2}{cmd:. kperrony y z1 z2 z3, lags(2)}{p_end}
{phang2}{cmd:. kperrony y z1 z2 z3, lags(2) trend}{p_end}
{phang2}{cmd:. kperrony y z1 z2 z3, nodols}{p_end}

{p 4 4 2}{bf:Example 5:} synthetic data with one I(0) regressor ({opt xzero()}) and one
I(1) regressor: DOLS with and without the serial correlation correction, and the
static regression.{p_end}

{phang2}{cmd:. use "https://eruygurakademi.com/datasets/kperrony/synth_p1q1.dta", clear}{p_end}
{phang2}{cmd:. kperrony y z1, xzero(x1) lags(2)}{p_end}
{phang2}{cmd:. kperrony y z1, xzero(x1) lags(2) nosc}{p_end}
{phang2}{cmd:. kperrony y z1, xzero(x1) nodols}{p_end}

{title:Numerical equivalence with the original MATLAB code}

{p 4 4 2}
The regime-wise coefficient estimates and their HAC standard errors follow the
authors' own construction (function {it:get_Regoutput} of the empirical programs:
the regime partition is built on the full sample and the DOLS trimming is applied
afterwards) and are validated against Octave runs of that function on all four
specifications of Example 1.

{p 4 4 2}
The Arai-Kurozumi statistic is computed exactly as in the authors' AKtest function
(it matches Octave runs of that function to at least 13 significant digits on the
Example 1 specifications). Its critical value is simulated; for exact cross-engine
comparison the undocumented option {cmd:pmseed(#)} replaces the normal draws with
a deterministic Park-Miller stream shared by the Octave reference programs, with
{opt akreps(#)} controlling the replication count.

{p 4 4 2}The ten commands above, run with the {opt fullprecision} option, are the validation
suite of {cmd:kperrony}. They were run against the authors' unmodified MATLAB code executed
under GNU Octave 8.4.0 on exactly the same data, and together they cover every computational
branch of the code: pure I(1) and mixed I(1)-I(0) regressors, DOLS and static regressions,
serial correlation correction on and off, nontrending and trending critical values. In every
run the selected number of breaks and all estimated break dates are identical, the minimized
sums of squared residuals agree to at least 14 significant digits, and the SEQ and second-step
statistics agree to at least 10 significant digits. All supF and UDmax statistics agree to at
least 12 significant digits, with one documented exception: in the two unrestricted money
demand regressions the DOLS design contains 18 leads-and-lags columns and the relevant moment
matrices have condition numbers near 1e7, so the supF statistics agree to 8-9 significant
digits, a bound imposed by floating point conditioning that applies between any two linear
algebra libraries (verified against a 50-digit precision computation of the same statistics).
The UDmax statistics from the two engines, displayed at 4 decimal
places (the default display precision of {cmd:kperrony}):{p_end}

    command                                    Octave       kperrony
    {hline 72}
    kperrony ly lydp lr, lags(4)                   423.0347       423.0347
    kperrony lm lr, lags(4)                        613.1447       613.1447
    kperrony ly lydp r, lags(4)                    511.1488       511.1488
    kperrony lm r, lags(4)                         674.4843       674.4843
    kperrony y z1 z2 z3, lags(2)                  1152.5178      1152.5178
    kperrony y z1 z2 z3, lags(2) trend            1152.5178      1152.5178
    kperrony y z1 z2 z3, nodols                    821.3739       821.3739
    kperrony y z1, xzero(x1) lags(2)              1754.5318      1754.5318
    kperrony y z1, xzero(x1) lags(2) nosc         2940.8324      2940.8324
    kperrony y z1, xzero(x1) nodols               1764.2202      1764.2202
    {hline 72}
{p 4 4 2}The original MATLAB code is distributed by the authors at Pierre Perron's code
archive, {browse "https://blogs.bu.edu/perron/codes/"} (file
{cmd:jtsa12609-sup-0001-supinfo.zip}, which also contains the procedures of Kejriwal and
Perron 2010). A self-contained Octave replication package - the same unmodified code, the
three datasets in CSV form, and a master script that runs all ten cases and prints every
statistic with 15 significant digits - is available at
{browse "https://eruygurakademi.com/datasets/kperrony/kperrony_octave_validation.zip"}.
To run it: install GNU Octave (no additional packages are required), unzip the archive into a
folder, start Octave in that folder, and type {cmd:run_all}. The script writes
{cmd:octave_reference_outputs.txt}, in which each case is labeled with the exact
{cmd:kperrony} command it replicates, so the file can be compared line by line with the
{opt fullprecision} output of {cmd:kperrony} in Stata.{p_end}

{title:Stored results}

{p 4 4 2}{cmd:kperrony} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(nb)}}selected number of breaks{p_end}
{synopt:{cmd:r(udmax)}}UDmax statistic{p_end}
{synopt:{cmd:r(udmax_cv)}}UDmax critical value{p_end}
{synopt:{cmd:r(T)}}number of observations in the sample{p_end}
{synopt:{cmd:r(Teff)}}effective number of observations after DOLS trimming{p_end}
{synopt:{cmd:r(h)}}minimum regime length{p_end}
{synopt:{cmd:r(lags)}}number of DOLS leads and lags{p_end}
{synopt:{cmd:r(p)}}number of I(0) regressors{p_end}
{synopt:{cmd:r(q)}}number of I(1) regressors{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(supf)}}k, supF(k), critical value, SSR(k), k = 1,...,5{p_end}
{synopt:{cmd:r(seq)}}sequential tests: k, SEQ(k+1|k), critical value{p_end}
{synopt:{cmd:r(brdates)}}break dates: observation number and time value{p_end}
{synopt:{cmd:r(coef)}}regime-wise coefficient estimates (rows = regimes){p_end}
{synopt:{cmd:r(hacse)}}HAC standard errors of the regime-wise estimates{p_end}
{synopt:{cmd:r(stdse)}}homoskedastic OLS standard errors of the same estimates{p_end}
{synopt:{cmd:r(ak)}}Arai-Kurozumi test statistic{p_end}
{synopt:{cmd:r(akcv)}}its simulated critical value{p_end}
{synopt:{cmd:r(akreps)}}replications used for the simulated critical value{p_end}
{synopt:{cmd:r(twostep)}}second-step tests: F, chi-squared critical value, df{p_end}
{synopt:{cmd:r(datevec)}}break date matrix for all break numbers k = 1,...,5{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(coefnames)}}names of the breaking coefficients{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(cmd)}}{cmd:kperrony}{p_end}

{title:References}

{p 4 8 2}Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent covariance
matrix estimation. {it:Econometrica} 59: 817-858.{p_end}

{p 4 8 2}Arai, Y., and E. Kurozumi. 2007. Testing for the null hypothesis of cointegration with
a structural break. {it:Econometric Reviews} 26: 705-739.{p_end}

{p 4 8 2}Bai, J., and P. Perron. 1998. Estimating and testing linear models with multiple
structural changes. {it:Econometrica} 66: 47-78.{p_end}

{p 4 8 2}Bai, J., and P. Perron. 2003. Computation and analysis of multiple structural change
models. {it:Journal of Applied Econometrics} 18: 1-22.{p_end}

{p 4 8 2}Kejriwal, M., X. Yu, and P. Perron. 2020. Bootstrap procedures for detecting
multiple persistence shifts in heteroskedastic time series. {it:Journal of Time
Series Analysis} 41: 676-690.{p_end}

{p 4 8 2}Kejriwal, M. 2008. Cointegration with structural breaks: an application to the
Feldstein-Horioka puzzle. {it:Studies in Nonlinear Dynamics and Econometrics} 12(1), Article
3.{p_end}

{p 4 8 2}Kejriwal, M., and P. Perron. 2008. Data dependent rules for the selection of the
number of leads and lags in the dynamic OLS cointegrating regression. {it:Econometric Theory}
24: 1425-1441.{p_end}

{p 4 8 2}Kejriwal, M., and P. Perron. 2010. Testing for multiple structural changes in
cointegrated regression models. {it:Journal of Business and Economic Statistics} 28:
503-522.{p_end}

{p 4 8 2}Kejriwal, M., P. Perron, and X. Yu. 2021. A two-step procedure for testing partial
parameter stability in cointegrated regression models. {it:Journal of Time Series Analysis},
DOI: 10.1111/jtsa.12609.{p_end}

{p 4 8 2}Park, J. Y. 1992. Canonical cointegrating regressions. {it:Econometrica} 60:
119-143.{p_end}

{p 4 8 2}Phillips, P. C. B., and B. E. Hansen. 1990. Statistical inference in instrumental
variables regression with I(1) processes. {it:Review of Economic Studies} 57: 99-125.{p_end}

{p 4 8 2}Saikkonen, P. 1991. Asymptotically efficient estimation of cointegration regressions.
{it:Econometric Theory} 7: 1-21.{p_end}

{title:Author}

{p 4 4 2}H. Ozan Eruygur{p_end}
{p 4 4 2}AHBV University, Ankara, Turkiye.{p_end}
{p 4 4 2}Department of Economics{p_end}
{p 4 4 2}{browse "https://www.ozaneruygur.com"}{p_end}
{p 4 4 2}eruygur@gmail.com{p_end}

{p 4 4 2}Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye.{p_end}
{p 4 4 2}{browse "https://www.eruygurakademi.com"}{p_end}
{p 4 4 2}eruygurakademi@gmail.com{p_end}

{p 4 4 2}{bf:kperrony} v1.0.0 - July 2026{p_end}

{p 4 4 2}The tests implemented here were proposed by Mohitosh Kejriwal (Krannert School of
Management, Purdue University) and Pierre Perron (Department of Economics, Boston University)
in Kejriwal and Perron (2010), and extended with the two-step procedure by Kejriwal, Perron,
and Xuewen Yu (Krannert School of Management, Purdue University) in Kejriwal, Perron, and Yu
(2021). {bf:kperrony} is a Stata/Mata port of the original MATLAB code written by Xuewen Yu
(June 2021), distributed by the authors at Pierre Perron's code archive
({browse "https://blogs.bu.edu/perron/codes/"}) and as supporting information of the 2021
article.{p_end}

{p 4 4 2}{bf:Please cite as:}{p_end}

{p 4 4 2}Eruygur, H. O. 2026. {bf:kperrony}: Determining the number & dates of structural
breaks in cointegrated equations, with regime-wise estimates and stability tests.
Stata package version 1.3.0. Available from:
{browse "https://www.eruygurakademi.com"}.{p_end}

{title:Also see}

{p 4 8 2}Help: {help tsset}, and the author's related packages {help kypshift},
{help maki}, {help kpssbr}, {help pocoint}, {help ckptest}, {help kapetanios},
{help narayanp}, and {help leestra} (each if installed).{p_end}
