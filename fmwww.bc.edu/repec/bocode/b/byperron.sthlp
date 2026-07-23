{smcl}
{* *! version 1.5.1 22jul2026}{...}
{title:Title}

{pstd}{cmd:byperron} {hline 2} Determining structural breaks in time series models
(Bai-Perron 2003; Yamamoto-Perron 2013){p_end}


{title:Syntax}

{p 8 16 2}
{cmd:byperron} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt meth:od(string)}}estimation method: {cmd:full}, {cmd:trun}, or {cmd:band};
default is {cmd:trun}{p_end}
{synopt :{opt wl(#)}}lower band limit as a multiple of pi; required with
{cmd:method(band)}{p_end}
{synopt :{opt wh(#)}}upper band limit as a multiple of pi; required with
{cmd:method(band)}{p_end}
{synopt :{opt max:breaks(#)}}maximum number of breaks m; default is
{cmd:maxbreaks(5)}{p_end}
{synopt :{opt trim(#)}}trimming epsilon; one of 0.05, 0.10, 0.15, 0.20, 0.25; default is
{cmd:trim(0.15)}{p_end}
{synopt :{opt rob:ust(#)}}0 or 1; allow serial correlation and heteroskedasticity in the
errors; default is {cmd:robust(1)}{p_end}
{synopt :{opt hetdat(#)}}0 or 1; allow different moment matrices of the regressors across
segments; default is {cmd:hetdat(1)}{p_end}
{synopt :{opt hetvar(#)}}0 or 1; allow different error variances across segments; default
is {cmd:hetvar(0)}{p_end}
{synopt :{opt pre:whit(#)}}0 or 1; apply VAR(1) prewhitening to the HAC estimator; only
with {cmd:method(full)}; default is {cmd:prewhit(0)}{p_end}
{synopt :{opt nodemean}}do not center the data; use {depvar} and {indepvars} exactly as
supplied. By default {cmd:byperron} demeans them over the estimation sample{p_end}
{synopt :{opt det:rend(string)}}detrend the dependent variable before estimation:
{cmd:none} (the default) or {cmd:linear}. Applies to {depvar} only, as in the empirical
application of Yamamoto and Perron (2013){p_end}
{synopt :{opt noal:ign}}do not align the sample to the differenced regressor frame; use
every feasible observation{p_end}
{synoptline}
{p 4 6 2}
{it:indepvars} are the regressors whose coefficients are allowed to change across regimes
(pure structural change model). Time-series operators are allowed. At most 10 regressors
are allowed (critical value tables).{p_end}


{title:Description}

{pstd}
{cmd:byperron} estimates and tests multiple structural changes in linear time series
models, implementing both the classical time domain procedure of Bai and Perron (1998,
2003) and the band spectral regression approach of Yamamoto and Perron (2013). All
procedures require I(0) variables. The asymptotic theory of Bai and Perron (1998, 2003)
explicitly precludes integrated variables (variables with an autoregressive unit root)
while permitting trending regressors, and the band spectral framework of Yamamoto and
Perron (2013) maintains short memory stationarity of the data (their Assumption 2.1). Do
not apply the command to unit root series: difference them first, which the {cmd:D.}
operator does internally. For cointegrating relationships among I(1) variables with
structural breaks, see the author's {helpb kperrony} command.{p_end}

{pstd}
The break dates are obtained by global minimization of the sum of squared residuals
computed from the retained frequency components, using the dynamic programming algorithm
of Bai and Perron (1998, 2003) applied to segment-specific real finite Fourier transforms
(Harvey 1978).{p_end}

{pstd}
The command reports: (a) the supF tests of 0 versus k breaks for k = 1, ..., m; (b) the
double maximum tests UDmax and WDmax against an unknown number of breaks; (c) the
sequential supF(l+1|l) tests for l = 1, ..., m-1 computed from the global optimizers under
the null, as in the original Bai-Perron program, together with the implied new break date;
(d) the break dates from the global minimization for each number of breaks with the
associated band spectral sum of squared residuals. Asymptotic critical values at the 10,
5, 2.5, and 1 percent levels are those of Bai and Perron (1998, 2003).

{pstd}
This command is an exact port of the official MATLAB code bsr_codes (Yohei Yamamoto,
February 19, 2013) accompanying the article, including all of its numerical conventions.
The full spectrum method reproduces the Bai and Perron time domain procedure.


{title:Options}

{dlgtab:Method and frequency band}

{phang}
{opt meth:od(string)} selects the frequency set on which the tests and the break dates are
computed. The names abbreviate the spectrum used: {cmd:full} stands for the
{it:full spectrum} (all frequencies are used; this is the classical Bai-Perron time domain
procedure), {cmd:trun} for the {it:truncated spectrum} (the lowest ceil(log(n))
frequencies of each segment of length n are removed), and {cmd:band} for the
{it:band spectrum} (only the frequencies in the band given by {opt wl()} and {opt wh()}
are used). The truncated and band spectra are the two methods proposed by the band
spectral regression approach of Yamamoto and Perron (2013); the full spectrum is the
classical benchmark that they extend. The default is {cmd:method(trun)}, the protected
general test. See
{it:Methods} below for guidance on the choice.{p_end}

{phang}
{opt wl(#)} and {opt wh(#)} set the lower and upper limits of the frequency band as
multiples of pi, with 0 <= {it:wl} < {it:wh} <= 1; they are required by, and only allowed
with, {cmd:method(band)}. The zero frequency is included only with {cmd:wl(0)}. A
frequency {it:w}*pi corresponds to cycles of period 2/{it:w} periods of the data, so a
window of cycle lengths from {it:p1} to {it:p2} periods is obtained with
{cmd:wl(}2/{it:p2}{cmd:)} and {cmd:wh(}2/{it:p1}{cmd:)}. For quarterly data, cycles
between 4 and 32 quarters (the business cycle band) correspond to
{cmd:wl(0.0625) wh(0.5)}.{p_end}

{dlgtab:Breaks and trimming}

{phang}
{opt max:breaks(#)} sets the maximum number of breaks m. Global break dates are estimated
for 1 to m breaks, the supF tests are computed for k = 1, ..., m, and the sequential tests
up to supF(m|m-1), so the sequential procedure can select at most m breaks. The admissible
maximum depends on {opt trim()} through the tabulated critical values (for example 5 with
{cmd:trim(0.15)}, 8 with {cmd:trim(0.10)}, 9 with {cmd:trim(0.05)}); the default is
{cmd:maxbreaks(5)}.{p_end}

{phang}
{opt trim(#)} sets the minimal admissible regime length as a fraction of the sample: each
regime must contain at least h = ceil({it:trim}*T) observations. Admissible values are
0.05, 0.10, 0.15, 0.20 and 0.25; the
default is {cmd:trim(0.15)}, the value used in Yamamoto and Perron (2013). A smaller
trimming admits
shorter regimes and more breaks at the cost of less precise dating. These are exactly the
trimmings for which Bai and Perron (2003) tabulate critical values, with
maximum numbers of breaks 9, 8, 5, 3 and 2 respectively; Bai and Perron (2003) recommend
the larger trimmings when heterogeneity or serial correlation is allowed in the
construction of the tests.{p_end}

{dlgtab:Covariance}

{phang}
{opt rob:ust(#)} selects the covariance estimator used in the test statistics, as in the
original code. With {cmd:robust(1)}, the default, the covariance is robust to
heteroskedasticity and, for {cmd:method(full)}, to serial correlation (HAC with the
quadratic spectral kernel and the automatic bandwidth of Andrews (1991) based on an AR(1)
approximation); for {cmd:method(trun)} and {cmd:method(band)} the White (1980) estimator
is applied to the filtered data. With {cmd:robust(0)} a homoskedastic covariance is
used. Following the documentation of the Bai-Perron program, {cmd:robust(1)} should not be
combined with lagged dependent variables among the regressors; use {cmd:robust(0)} in that
case.{p_end}

{phang}
{opt hetdat(#)} controls the moment matrices of the regressors in the construction of the
covariance entering the tests (the hetdat option of the Bai-Perron program). With
{cmd:hetdat(1)}, the default and the setting of the original script, the moment matrix is
estimated separately on each segment; with {cmd:hetdat(0)} a single moment matrix
estimated from the full sample is imposed on every segment. Keep the default unless there
are firm grounds to assume that the distribution of the regressors is identical across
regimes: estimating the matrices freely costs little, while imposing equality wrongly
distorts the tests.{p_end}

{phang}
{opt hetvar(#)} controls the variance of the residuals in the construction of the
covariance entering the tests (the hetvar option of the Bai-Perron program). With
{cmd:hetvar(0)}, the default and the setting of the original script, a common variance
estimated from the full sample is used; with {cmd:hetvar(1)} the variance is estimated
separately on each segment. Set {cmd:hetvar(1)} when the variance of the errors may itself
change across regimes, for example when a volatility moderation accompanies the
coefficient changes. Following the documentation of the Bai-Perron program, the option is
relevant under {cmd:robust(0)}; with {cmd:robust(1)} the robust long run estimator is used
instead.{p_end}

{phang}
{opt pre:whit(#)} applies VAR(1) prewhitening in the HAC covariance estimator and is only
allowed with {cmd:method(full)} under {cmd:robust(1)}. The default is {cmd:prewhit(0)},
the setting of the original script. Prewhitening fits a VAR(1) to the residuals before the
kernel estimation; use it when the errors are strongly serially correlated.{p_end}

{dlgtab:Data handling}

{phang}
{opt nodemean} skips the internal demeaning and uses the variables exactly as supplied. Do
not use this option unless you know exactly what you are doing. In particular, if you have
not demeaned the data yourself beforehand, this option must not be used: the regression
would then include neither a constant term nor centered variables, so the intercept would
be omitted from a model that requires one, and every reported statistic would refer to
that misspecified regression. Its only legitimate uses are the bit for bit replication
of an external pipeline whose data are already centered, and exercises that deliberately
require no centering. Demeaning an already centered series changes nothing beyond the last
floating point digits, so with prepared data it is always safe to leave the default on.
See {it:Methods} for why a constant term must not be included.{p_end}

{phang}
{opt det:rend(string)} linearly detrends the dependent variable before estimation
({cmd:linear}), as in the level specification of the empirical application of Yamamoto and
Perron (2013); the default
{cmd:none} leaves it untouched. Detrending applies to the dependent variable only; see
{it:Methods} for the detrend window.{p_end}

{phang}
{opt noal:ign} disables the automatic alignment of the sample to the differenced regressor
frame (see {it:Methods}) and uses every feasible observation instead. It has an effect
only when a regressor carries {cmd:D.} or {cmd:S.} operators. Use it when the largest
feasible sample is preferred over exact correspondence with the sample convention of the
original code; the two differ only by the first observation of the sample.{p_end}


{title:Methods}

{dlgtab:The three methods}

{pstd}
The method names abbreviate the frequency set used: {cmd:full} stands for the full
spectrum, {cmd:trun} for the truncated spectrum, and {cmd:band} for the band spectrum.
The terminology is that of Yamamoto and Perron (2013): the columns of their Table 9 are
labeled Full, Truncated and Cycle, and the method switch of the original script
{cmd:main.m} reads 1: full, 2: truncation, 3: business-cycle. The Cycle case is the band
method applied to the business cycle frequencies, so {cmd:method(band)} is its general
form.{p_end}

{pstd}
{cmd:method(full)} uses all frequencies; this is the standard time domain estimation of
Bai and Perron (1998). With {cmd:robust(1)} the covariance matrix uses a HAC estimator
with the quadratic spectral kernel and the automatic bandwidth of Andrews (1991) based on
an AR(1) approximation, optionally with VAR(1) prewhitening ({cmd:prewhit(1)}).

{pstd}
{cmd:method(trun)} removes the lowest L = ceil(log(n)) real Fourier components of each
segment, where n is the segment length, as suggested in Section 3 of Yamamoto and Perron
(2013). This makes
the tests robust to low frequency contaminations such as level shifts or trends in the
errors. With {cmd:robust(1)} the covariance matrix uses the White (1980)
heteroskedasticity robust estimator applied to the filtered data.

{pstd}
{cmd:method(band)} uses only the frequencies in the band [wl*pi, wh*pi] specified through
{opt wl()} and {opt wh()}. For example, business cycle frequencies for quarterly data
(periods between 4 and 32 quarters) correspond to {cmd:wl(0.0625) wh(0.5)}. The zero
frequency is included only when {cmd:wl(0)} is specified. The White (1980) covariance
estimator is used with {cmd:robust(1)}, as in {cmd:method(trun)}.

{dlgtab:Same statistics, same critical values}

{pstd}
The three methods compute the same battery of statistics on different frequency sets. When
no frequency is discarded the transformation is orthonormal and preserves the sum of
squared residuals, so the full spectrum regression is algebraically identical to the time
domain regression: {cmd:method(full)} therefore delivers exactly the classical Bai-Perron
tests and break dates. Discarding frequencies breaks this identity and produces genuinely
spectral tests. A central result of Yamamoto and Perron (2013) is that the truncated and
band versions of the tests have the same limit distributions as their Bai-Perron
counterparts, which is why the same critical value tables apply to all three methods.

{dlgtab:Which method for which question}

{pstd}
The economic motivation is that many relationships are horizon specific, so that a single
coefficient estimated on the raw series mixes distinct mechanisms. Under the permanent
income hypothesis, consumption follows the persistent movements of income almost one for
one but responds weakly to transitory quarterly fluctuations, so the propensity to consume
out of income differs across horizons. Similarly, money growth and inflation move
essentially one for one at long horizons while the quarterly relation is weak. A full
spectrum regression delivers a mixture of these horizon specific coefficients, and a
structural change test based on it asks a correspondingly mixed question; the spectral
framework makes it possible to ask the question horizon by horizon.

{pstd}
Choosing between the methods: use {cmd:method(full)} for the classical general stability
test; use {cmd:method(trun)} for a general test protected against low frequency
contamination (the number of discarded frequencies follows a rule of the segment length,
it is not a user choice): typical contaminants are slow components unrelated to the
relationship of interest, such as demographic trends and labor force participation
movements in per capita hours, trend breaks in productivity, or the secular decline of
trend inflation in Phillips curve estimation, all of which masquerade as coefficient
breaks in full spectrum tests; use {cmd:method(band)} for hypotheses attached to a
particular horizon: the Phillips curve and Okun's law are business cycle relationships, so
the question of whether the Phillips curve has flattened is properly a question about its
slope at business cycle frequencies, to be separated from the footprint of declining trend
inflation at the low frequencies. A frequency {it:w}*pi corresponds to a cycle period of
2/{it:w} time units, so cycles with periods between {it:p1} and {it:p2} periods of the
data map to {cmd:wl(}2/{it:p2}{cmd:)} and {cmd:wh(}2/{it:p1}{cmd:)}. For quarterly data,
periods between 4 and 32 quarters (1 to 8 years, the business cycle band of Yamamoto and
Perron (2013))
give {cmd:wl(0.0625) wh(0.5)}.

{dlgtab:What the simulations show}

{pstd}
The simulations in Yamamoto and Perron (2013) support this division of labor and clarify
the trade-offs. When the break is common to all frequencies and there is no contamination,
the full spectrum test has the highest power, so nothing is lost by using the classical
procedure in the textbook case.{p_end}

{pstd}
When the errors carry low frequency contamination (level shifts, remaining trends, long
memory), the untruncated tests suffer serious size distortions and tend to find breaks
that are not there. Truncation restores the size and improves the size-adjusted power
considerably; the results are insensitive to the particular truncation rule, and removing
even a single frequency already yields a dramatic improvement over the untruncated
test.{p_end}

{pstd}
When the break is confined to a frequency band, three cases must be distinguished.
Testing in the correct band gives the highest power, because only the frequencies that
carry the break enter the regression; the gains over the full spectrum are larger when the
break lies in higher frequencies. The full spectrum test keeps positive but diluted power:
the informative frequencies are in the pool, but mixed with the noise of the frequencies
whose coefficients never change. Testing in a band that does not contain the break leaves
the test with no power at all: every frequency component entering the regression then has
constant coefficients, so the null hypothesis is effectively true within that band, and
the rejection probability stays at the nominal significance level whatever the size of the
break elsewhere (power equals size). A band should therefore reflect a genuine hypothesis
about where the instability lives.{p_end}

{pstd}
The flip side is a diagnostic virtue. A break date answers the question of when the
relationship changed; running the test over different frequency sets answers the question
of at which cycle lengths it changed, because only the frequency sets that carry the break
lead to rejections. The empirical application of Yamamoto and Perron (2013) is exactly
such an exercise: the full spectrum tests find breaks in the hours-productivity relation,
but once the lowest frequencies are removed by the truncation, and within the business
cycle band, none of the tests is significant. The pattern of rejections therefore places
the instability in the lowest frequencies, and shows that the relation is stable over any
band excluding them, in particular over the business cycle band.{p_end}

{pstd}
In short, the truncated and band methods are complements rather than substitutes, of each
other and of the full spectrum test. The truncated test establishes whether an instability
survives once the most contamination prone frequencies are removed; the band test
establishes whether the relationship is stable at the horizon where the economic
hypothesis lives; and the comparison of the results across the three methods attributes a
detected break to the horizon responsible for it, as in the hours and productivity
application above. The methods generalize the Bai-Perron procedure rather than replace it,
and reduce to it exactly under {cmd:method(full)}.{p_end}

{dlgtab:Computational conventions}

{pstd}
Following the original code, the supF statistics for {cmd:method(trun)} and
{cmd:method(band)} use the number of retained Fourier components in the degrees of freedom
correction. The regressors should not include a constant term: under truncation or a band
excluding frequency zero the constant column is annihilated by the filter and the moment
matrix becomes singular. For this reason {cmd:byperron} demeans the dependent variable
and every regressor over the estimation sample by default, exactly as in the empirical
application of Yamamoto and Perron (2013) (footnote 6). You therefore pass the variables
directly, without
generating centered copies and without a constant term.

{dlgtab:Demeaning}

{pstd}
Do not use {cmd:nodemean} unless you know exactly what you are doing. If the data have not
been demeaned beforehand, the option must not be used: the regression would then include
neither a constant term nor centered variables, so the intercept would be omitted from a
model that requires one, and all reported statistics would refer to that misspecified
regression. Demeaning an
already centered series changes nothing beyond the last floating point digits, so with
prepared data the default can always be left on.

{dlgtab:Detrending}

{pstd}
With {cmd:detrend(linear)} the dependent variable is linearly detrended before estimation,
exactly as in the level specification of the empirical application of Yamamoto and Perron
(2013). The trend is
fitted by a no-constant regression on 1, 2, ..., n and the residuals are used; the
subsequent demeaning absorbs the level. The linear trend is fitted on the estimation
sample extended back by the maximum lag order among the regressors: the original code
detrends the dependent variable before the regressor lags drop the low order observations
at the front of the sample, and the extended window reproduces that span. Observations
before the estimation sample enter the detrend window whenever the dependent variable is
observed there, regardless of {it:if} and {it:in}. Detrending applies to the dependent
variable only, and only the linear form used in Yamamoto and Perron (2013) is provided.
With
{cmd:detrend(none)}, the default, no detrending is performed and the behavior of the
command is completely unchanged.

{dlgtab:Sample alignment}

{pstd}
When a regressor involves differencing, {cmd:byperron} aligns the sample exactly as the
original code does: the differenced regressor defines a frame that begins where the
difference first becomes computable (the observation for which no growth rate exists is
discarded), and all further transformations are computed within that frame. In particular
the dependent variable enters from the second observation of the frame onward, whether it
is differenced (its own difference consumes that observation) or in levels (Yamamoto and
Perron (2013) use the same sample for both specifications), and the regressor lags are
then taken within the
frame. The data themselves are untouched. This alignment is automatic whenever a regressor
carries {cmd:D.} or {cmd:S.} operators and does nothing otherwise; specify {opt noalign}
to use every feasible observation instead.

{pstd}
Together with time-series operators in the varlist, this means no manual data preparation
at all: pass the raw series and let the command difference ({cmd:D.}), lag ({cmd:L.}),
detrend, demean and align internally.

{dlgtab:Numerical properties}

{pstd}
Two numerical properties of the truncated and band methods are worth knowing. First, the
minimized sum of squared residuals is not comparable across different numbers of breaks:
each segment is filtered with a selection that depends on its own length, so the SSR
reported for m+1 breaks can exceed the one reported for m breaks. This is a property of
the objective function, it carries no implication for the tests, and the number of breaks
is selected from the tests, never by comparing SSRs. Second, the sequential supF(l+1|l)
statistics can coincide across several l: when the conditioning break sets share the same
final segment, the best additional break is the same one in that segment each time.

{dlgtab:Selection of the number of breaks}

{pstd}
The output ends with the reporting rule used for the Dates row of Table 9 in Yamamoto and
Perron (2013): if
the supF test of 0 versus 1 break is significant at the 5 percent level, the number of
breaks is increased while the sequential supF(l+1|l) tests remain significant at that
level, and the break dates of the global minimization at the selected number are reported;
otherwise no break is selected. When the data are {cmd:tsset}, break dates are displayed
as values of the time variable (calendar dates if the time variable carries a date
format); the matrix {cmd:e(datevec)} stores the corresponding observation indices within
the estimation sample. Without a time variable the indices themselves are displayed. The
estimation sample should be a single uninterrupted stretch of time series observations.


{title:Examples}

{dlgtab:Replication of Table 9(b) of Yamamoto and Perron (2013)}

{pstd}Replication of the empirical example of Yamamoto and Perron (2013), Table 9(b),
using the original hours-productivity data, served from the author's site and also shipped
with the package. File {cmd:data_hour.csv}: column 1 ({cmd:v1}) is log productivity,
column 2 ({cmd:v2}) is log hours, quarterly, 1948Q1 to 2009Q4 (248 observations,
unmodified). No manual preparation is needed: the raw series are passed with time-series
operators, and differencing, lagging, detrending, demeaning and the sample alignment are
all done by the command. The regressors are the first four lags of productivity growth,
{cmd:L(1/4).D.v1}; the sample alignment of the original code is applied automatically.
These commands reproduce the Table 9(b) results exactly (T = 242, sample 1949Q3 to
2009Q4).{p_end}

{phang2}{cmd:. import delimited "https://eruygurakademi.com/datasets/byperron/data_hour.csv", asdouble clear}{p_end}
{phang2}{cmd:. gen t = tq(1948q1) + _n - 1}{p_end}
{phang2}{cmd:. format t %tq}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Hours in levels (linearly detrended by the command, as in Yamamoto and Perron
(2013)), truncated
method{p_end}
{phang2}{cmd:. byperron v2 L(1/4).D.v1, detrend(linear)}{p_end}

{pstd}Hours in first differences (differenced by the {cmd:D.} operator), full
spectrum{p_end}
{phang2}{cmd:. byperron D.v2 L(1/4).D.v1, method(full)}{p_end}

{pstd}Business cycle band (cycles of 4 to 32 quarters: wl = 2/32 = 0.0625, wh = 2/4 =
0.5){p_end}
{phang2}{cmd:. byperron D.v2 L(1/4).D.v1, method(band) wl(0.0625) wh(0.5)}{p_end}

{dlgtab:General use and options illustrated}

{pstd}
Structural change tests with a standard Stata example dataset (West German quarterly data,
Lutkepohl 1993). The data are already {cmd:tsset}, so the reported break dates are labeled
with calendar quarters. The variables are passed directly; {cmd:byperron} demeans them
internally. Each call below states its purpose.{p_end}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}

{pstd}
The default call: the truncated spectrum, a general stability test protected against low
frequency contamination.{p_end}
{phang2}{cmd:. byperron consump inc inv}{p_end}

{pstd}
The classical procedure of Bai and Perron (2003), using all frequencies; the most powerful
choice when no contamination is suspected and the break may affect all horizons.{p_end}
{phang2}{cmd:. byperron consump inc inv, method(full)}{p_end}

{pstd}
Stability over business cycle frequencies only (cycles of 4 to 32 quarters: wl = 2/32 =
0.0625, wh = 2/4 = 0.5); use when the hypothesis concerns a specific horizon.{p_end}
{phang2}{cmd:. byperron consump inc inv, method(band) wl(0.0625) wh(0.5)}{p_end}

{pstd}
Finer trimming: regimes as short as 10 percent of the sample are admitted; use when short
regimes are plausible, at the cost of noisier dating.{p_end}
{phang2}{cmd:. byperron consump inc inv, trim(0.10)}{p_end}

{pstd}
Coarser trimming: each regime must cover at least 20 percent of the sample, and the
critical value tables then allow at most 3 breaks.{p_end}
{phang2}{cmd:. byperron consump inc inv, method(trun) maxbreaks(3) trim(0.20)}{p_end}

{pstd}
Homoskedastic covariance; only when the errors are believed homoskedastic and, for the
full spectrum, serially uncorrelated. Also the appropriate choice when lagged dependent
variables are included among the regressors.{p_end}
{phang2}{cmd:. byperron consump inc inv, method(full) robust(0)}{p_end}

{pstd}
Imposing identical regressor moment matrices across regimes; the default {cmd:hetdat(1)}
is recommended, so this is for the rare case in which equality is known to hold.{p_end}
{phang2}{cmd:. byperron consump inc inv, hetdat(0)}{p_end}

{pstd}
Allowing the error variance to change across regimes; use when variance shifts may
accompany the coefficient changes (relevant under {cmd:robust(0)}).{p_end}
{phang2}{cmd:. byperron consump inc inv, robust(0) hetvar(1)}{p_end}

{pstd}
VAR(1) prewhitening of the HAC estimator; use when the errors are strongly serially
correlated.{p_end}
{phang2}{cmd:. byperron consump inc inv, method(full) prewhit(1)}{p_end}

{pstd}
Removing a linear trend from the dependent variable before estimation, as in the level
specification of Yamamoto and Perron (2013).{p_end}
{phang2}{cmd:. byperron consump inc inv, detrend(linear)}{p_end}


{title:Equivalence with the original MATLAB code}

{dlgtab:The original script}

{pstd}
The original code is driven by the script {cmd:main.m} of {cmd:bsr_codes}. The user sets
two switches at the top of the script, {cmd:data_transform} (0 for hours in levels, 1 for
first differences) and {cmd:method} (1 full spectrum, 2 truncation, 3 business cycle band
with {cmd:wl=pi*(1/16)} and {cmd:wh=pi*(1/2)}), and the script then differences log
productivity, aligns the series, linearly detrends hours in the level case, constructs the
four lags, demeans, and prints the tests.

{dlgtab:Running the original code yourself}

{pstd}
The results can be reproduced in MATLAB or in GNU Octave, step by step:{p_end}

{phang}
1. Click {browse "https://eruygurakademi.com/datasets/byperron/byperron_matlab.zip"}
and save the file.{p_end}

{phang}
2. Extract the zip file into a new folder (right click, Extract All on Windows).{p_end}

{phang}
3. Start MATLAB or Octave and make that folder the current folder: in MATLAB paste the
folder path into the address bar at the top of the window; in Octave use the file browser
panel on the left, or type {cmd:cd} followed by the folder path.{p_end}

{phang}
4. Open the file {cmd:run_byperron.m} (double click it in the file panel).{p_end}

{phang}
5. Two lines near the top of the file choose the specification: {cmd:data_transform}
(0 = hours in levels, 1 = hours in first differences) and {cmd:method} (1 = full spectrum,
2 = truncation, 3 = business cycle band). For the headline example set
{cmd:data_transform=1;} and {cmd:method=1;} and save the file.{p_end}

{phang}
6. Run the script: in MATLAB press the green Run button; in Octave type
{cmd:run_byperron} at the prompt and press Enter.{p_end}

{phang}
7. The results appear in the command window: the supF tests, UDmax and WDmax, the
sequential tests and the break dates.{p_end}

{phang}
8. Run the matching {cmd:byperron} command from the correspondence list below in Stata:
the numbers coincide digit for digit.{p_end}

{dlgtab:Correspondence and verified agreement}

{pstd}
The Stata replication starts from the same data file served online:

{phang2}{cmd:. import delimited "https://eruygurakademi.com/datasets/byperron/data_hour.csv", asdouble clear}{p_end}
{phang2}{cmd:. gen t = tq(1948q1) + _n - 1}{p_end}
{phang2}{cmd:. format t %tq}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}
Each configuration of the script then corresponds to one {cmd:byperron} command:

{pstd}MATLAB: {cmd:data_transform=1; method=1;}{p_end}
{phang2}{cmd:. byperron D.v2 L(1/4).D.v1, method(full)}{p_end}

{pstd}MATLAB: {cmd:data_transform=1; method=2;}{p_end}
{phang2}{cmd:. byperron D.v2 L(1/4).D.v1, method(trun)}{p_end}

{pstd}MATLAB: {cmd:data_transform=1; method=3;}{p_end}
{phang2}{cmd:. byperron D.v2 L(1/4).D.v1, method(band) wl(0.0625) wh(0.5)}{p_end}

{pstd}MATLAB: {cmd:data_transform=0;} with {cmd:method} 1, 2 or 3{p_end}
{phang2}{cmd:. byperron v2 L(1/4).D.v1, detrend(linear) method(full)}   (or {cmd:trun},
{cmd:band}){p_end}

{pstd}
For the first pair, {cmd:data_transform=1; method=1;} in MATLAB against
{cmd:byperron D.v2 L(1/4).D.v1, method(full)} in Stata, the printed results are (three
decimals shown; the agreement holds to at least 13 significant digits):{p_end}

{col 9}statistic{col 28}main.m{col 43}byperron
{col 9}{hline 45}
{col 9}SupF(1){col 28}18.922{col 43}18.922
{col 9}SupF(2){col 28}16.148{col 43}16.148
{col 9}SupF(3){col 28}12.259{col 43}12.259
{col 9}SupF(4){col 28}9.929{col 43}9.929
{col 9}SupF(5){col 28}7.423{col 43}7.423
{col 9}UDmax{col 28}18.922{col 43}18.922
{col 9}WDmax{col 28}18.986{col 43}18.986
{col 9}SupF(2|1){col 28}10.590{col 43}10.590
{col 9}SupF(3|2){col 28}8.780{col 43}8.780
{col 9}SupF(4|3){col 28}4.866{col 43}4.866
{col 9}Break date{col 28}1976:Q1{col 43}1976q1
{col 9}{hline 45}

{pstd}
The outputs are identical. For example, with {cmd:data_transform=1; method=1;} the script
reports SupF(1) = 18.9218, SupF(2|1) = 10.5899, UDmax = 18.9218 and the break date
1976:Q1; the command {cmd:byperron D.v2 L(1/4).D.v1, method(full)} reports exactly the
same numbers. The agreement has been verified for both specifications and all three
methods, statistic by statistic (the supF tests for k = 1, ..., 5, UDmax and WDmax, every
sequential test, and every global break date and sum of squared residuals for one to five
breaks), to at least 13 significant digits, with all break dates identical. The defaults
of {cmd:byperron}
({cmd:trim(0.15) maxbreaks(5) robust(1) hetdat(1) hetvar(0) prewhit(0)}) are the parameter
values set at the top of {cmd:main.m}.


{title:Stored results}

{pstd}
{cmd:byperron} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations T{p_end}
{synopt:{cmd:e(h)}}minimal segment length, ceil(trim*T){p_end}
{synopt:{cmd:e(q)}}number of regressors{p_end}
{synopt:{cmd:e(m)}}maximum number of breaks{p_end}
{synopt:{cmd:e(trim)}}trimming epsilon{p_end}
{synopt:{cmd:e(robust)}, {cmd:e(hetdat)}, {cmd:e(hetvar)}, {cmd:e(prewhit)}}covariance
options{p_end}
{synopt:{cmd:e(demean)}}1 if the data were demeaned internally, 0 with
{cmd:nodemean}{p_end}
{synopt:{cmd:e(detrend)}}1 if the dependent variable was linearly detrended, 0
otherwise{p_end}
{synopt:{cmd:e(align)}}1 if the differenced regressor frame alignment excluded
observations, 0 otherwise{p_end}
{synopt:{cmd:e(mseq)}}number of breaks selected by the sequential procedure at the 5
percent level (0 if the supF test of 0 versus 1 break is not significant){p_end}
{synopt:{cmd:e(wl)}, {cmd:e(wh)}}band limits in multiples of pi (method band only){p_end}
{synopt:{cmd:e(udmax)}}UDmax statistic{p_end}
{synopt:{cmd:e(wdmax)}}WDmax statistic (5 percent level weights){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:byperron}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(method)}}{cmd:full}, {cmd:trun}, or {cmd:band}{p_end}
{synopt:{cmd:e(detrendtype)}}{cmd:none} or {cmd:linear}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}regressors{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(supf)}}m x 1, supF tests of 0 vs k breaks{p_end}
{synopt:{cmd:e(wsupf)}}m x 1, weighted supF tests (5 percent level weights){p_end}
{synopt:{cmd:e(glb)}}m x 1, global minimal SSR for each number of breaks{p_end}
{synopt:{cmd:e(datevec)}}m x m, break dates; column k holds the k-break global
optimizers{p_end}
{synopt:{cmd:e(supfseq)}}(m-1) x 2, supF(l+1|l) statistics and new break dates{p_end}
{synopt:{cmd:e(cv_supf)}}4 x m, critical values of supF at 10, 5, 2.5, 1 percent{p_end}
{synopt:{cmd:e(cv_seq)}}4 x m, critical values of supF(l+1|l){p_end}
{synopt:{cmd:e(cv_dmax)}}4 x 2, critical values of UDmax and WDmax{p_end}

{p2col 5 18 22 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{title:References}

{phang}
Andrews, D. W. K. (1991). Heteroskedasticity and autocorrelation consistent covariance
matrix estimation. Econometrica 59, 817-858.

{phang}
Bai, J. and P. Perron (1998). Estimating and testing linear models with multiple
structural changes. Econometrica 66, 47-78.

{phang}
Bai, J. and P. Perron (2003). Computation and analysis of multiple structural change
models. Journal of Applied Econometrics 18, 1-22.

{phang}
Harvey, A. C. (1978). Linear regression in the frequency domain. International Economic
Review 19, 507-512.

{phang}
Yamamoto, Y. and P. Perron (2013). Estimating and testing multiple structural changes in
linear models using band spectral regressions. The Econometrics Journal 16, 400-429.


{title:Author}

{pstd}H. Ozan Eruygur{p_end}
{pstd}AHBV University, Ankara, Turkiye.{p_end}
{pstd}Department of Economics{p_end}
{pstd}{browse "https://www.ozaneruygur.com"}{p_end}
{pstd}eruygur@gmail.com{p_end}

{pstd}Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye.{p_end}
{pstd}{browse "https://www.eruygurakademi.com"}{p_end}
{pstd}eruygurakademi@gmail.com{p_end}

{pstd}{bf:byperron} v1.5.1 - July 2026{p_end}

{pstd}
The tests implemented here were proposed by Yohei Yamamoto (Hitotsubashi University) and
Pierre Perron (Boston University) in Yamamoto and Perron (2013). {bf:byperron} is a
Stata/Mata port of the original MATLAB code {cmd:bsr_codes}, developed by Yohei Yamamoto
and distributed on Pierre Perron's codes page at Boston University; the full spectrum
method implements the procedures of Bai and Perron (1998, 2003).{p_end}

{pstd}{bf:Please cite as:}{p_end}

{pstd}
Eruygur, H. O. 2026. {bf:byperron}: Determining structural breaks in time series models
(Bai-Perron 2003; Yamamoto-Perron 2013). Stata package version 1.5.1. Available from:
{browse "https://www.eruygurakademi.com"}.{p_end}
