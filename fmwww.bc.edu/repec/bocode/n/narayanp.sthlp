{smcl}
{* *! version 1.0.0}{...}
{viewerjumpto "Syntax" "narayanp##syntax"}{...}
{viewerjumpto "Description" "narayanp##description"}{...}
{viewerjumpto "Options" "narayanp##options"}{...}
{viewerjumpto "Remarks" "narayanp##remarks"}{...}
{viewerjumpto "Examples" "narayanp##examples"}{...}
{viewerjumpto "Stored results" "narayanp##results"}{...}
{viewerjumpto "References" "narayanp##references"}{...}
{title:Title}

{phang}
{bf:narayanp} {hline 2} Narayan-Popp (2010) unit root test with two structural breaks

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:narayanp} {varname} {ifin} [{cmd:,} {opt mod:el(#)} {opt pmax(#)} {opt ic(#)} {opt trim(#)} {opt seq:uential} {opt sim:ul} {opt bg} {opt bgl:ags(#)} {opt bgdf(#)}]

{pstd}
{cmd:narayanp} operates on a single time series and requires the data to be
{helpb tsset}. The series must have no missing values over the selected sample.

{marker description}{...}
{title:Description}

{pstd}
{cmd:narayanp} performs the Narayan and Popp (2010) Augmented Dickey-Fuller-type
test for a unit root that allows for two structural breaks at unknown dates. The
data-generating process is written as an unobserved-components model in which the
breaks are modelled as innovational outliers, so that a break takes effect
gradually rather than instantaneously (Narayan and Popp 2010, Eqs. 1-6). The test
allows for breaks under both the unit-root null and the trend-stationary
alternative, which reduces the spurious rejections that affect earlier
ADF-type break tests.

{pstd}
Two specifications are available, both for trending data: model M1 allows two
breaks in the level, and model M2 allows two breaks in the level and in the
slope. In both cases the test statistic is the t-ratio on the coefficient of
y(t-1); the unit-root null is rho = 1.

{pstd}
Time-series operators are accepted in {varname}, so the test can be applied
directly to transformed series such as first differences ({cmd:D.y}),
second differences ({cmd:D2.y}), or lags ({cmd:L.y}). The leading missing
values created by such operators are trimmed from the sample automatically;
internal gaps in the series still cause an error.

{pstd}
Three break-date selection procedures are available. By default {cmd:narayanp}
reproduces the GAUSS routine {bf:ADF_2breaks}: a full two-dimensional grid over
all admissible break-date pairs, choosing the pair for which the ADF t-ratio
itself is smallest. In that routine the breaks enter the test regression as
contemporaneous level-shift (and, for M2, trend-shift) dummies rather than
through the impulse-plus-lagged-dummy parameterization written in Eqs. 7-8 of
the paper. (Footnote 1 of the paper equates Eqs. 7-8 with the Perron-type
innovational-outlier regressions, which include one-period impulse dummies;
the step-dummy regression used by the GAUSS grid spans a smaller deterministic
set, so at given break dates its t-ratio generally differs from that of
Eqs. 7-8.) The paper's own grid criterion, Eq. 9, maximizes the joint
F-statistic of the impulse-dummy coefficients and is again different from the
minimum-t criterion of the GAUSS routine.

{pstd}
With the {opt sequential} option, {cmd:narayanp} instead implements the
two-step procedure proposed by Narayan and Popp (2010, Eqs. 10-11) directly on
the test regressions exactly as written in Eqs. 7-8: the first break date
maximizes the absolute t-value of the impulse-dummy coefficient in a
one-break regression, and, holding that date fixed, the second break date
maximizes the absolute t-value of the second impulse-dummy coefficient.
Narayan and Popp report that their simultaneous and sequential procedures give
similar results and prefer the sequential one because it requires on the order
of 2T regressions instead of T^2. See the option descriptions below for
details.

{pstd}
With the {opt simul} option, {cmd:narayanp} implements the paper's
simultaneous procedure (Eq. 9), again on the Eq. 7-8 regressions: all
admissible break-date pairs are searched, and the pair maximizing the
F-statistic for the joint significance of the two impulse-dummy coefficients
is selected. Break dates are thus identified from the estimated break
parameters, as in the sequential procedure, rather than from the unit-root
statistic itself. See the {help narayanp##remarks:Remarks} for how these
procedures relate to the minimum-t grid of the GAUSS routine.

{pstd}
The reported test statistic is compared with the critical values for the
endogenous (unknown) break case tabulated in Narayan and Popp (2010, Table 3),
which depend on the model and on the sample size {it:T}. As shown in that paper,
these critical values converge to the known-break (exogenous) values as the
sample grows, because the probability of correctly locating the breaks tends to
one.

{pstd}
Beyond the break-date procedures, {cmd:narayanp} adds a lag-selection rule not
present in the original routine: with the {opt bg} option the lag order is
chosen, at every candidate break configuration, by a general-to-specific
Breusch-Godfrey walk on that candidate's own test regression, so that the
selected lag is the smallest one whose residuals show no autocorrelation up to
a frequency-adaptive horizon. Whatever the lag-selection method, a
post-selection Breusch-Godfrey diagnostic for the winning regression is
reported and stored in {cmd:r(bgminp)}. See the option descriptions and the
{help narayanp##remarks:Remarks} below.

{marker options}{...}
{title:Options}

{phang}
{opt model(#)} selects the deterministic specification. Two models are
available, both for trending data, exactly as in Narayan and Popp (2010). The
lagged-level term whose t-ratio is the test statistic is written as y(t-1); D1(t)
and D2(t) are the level-shift dummies for the two breaks (D(t) = 1 for t greater
than the break date, 0 otherwise), and DT1(t), DT2(t) are the corresponding
trend-shift terms. In the deterministic component of the model, these correspond
to DU1, DU2 (and DT1, DT2) of Narayan and Popp (2010, Eqs. 4-6).

{p 8 12 2}
{cmd:model(1)} - M1, two breaks in level (the default; Model A in the Perron
break-model taxonomy). A constant and a deterministic trend are included; the
breaks shift only the level:{p_end}
{p 12 12 2}D.y(t) = a*y(t-1) + c + d*t + th1*D1(t) + th2*D2(t) + sum_j phi_j*D.y(t-j) + e(t){p_end}

{p 8 12 2}
{cmd:model(2)} - M2, two breaks in level and slope (Model C in the Perron
break-model taxonomy). A constant and a deterministic trend are included; the
breaks shift both the level and the trend slope:{p_end}
{p 12 12 2}D.y(t) = a*y(t-1) + c + d*t + th1*D1(t) + th2*D2(t) + g1*DT1(t) + g2*DT2(t) + sum_j phi_j*D.y(t-j) + e(t){p_end}

{p 8 8 2}
These are the reduced-form test regressions of Narayan and Popp (2010, Eqs. 7 and
8) written with contemporaneous break terms. A model with a break in slope only
(Perron's Model B) is not provided: Narayan and Popp (2010) study only the
level (M1) and level-and-slope (M2) cases and tabulate critical values for these
two alone.

{phang}
{opt pmax(#)} sets the maximum number of lags of D.y considered in the
augmentation. The default is {cmd:pmax(8)}. Use {cmd:pmax(0)} for no lags.

{phang}
{opt ic(#)} selects the lag-order criterion. {cmd:ic(1)} is the Akaike
information criterion; {cmd:ic(2)} is the Schwarz information criterion;
{cmd:ic(3)} (the default) is the general-to-specific t-significance rule, which
starts from {cmd:pmax} and drops the highest lag while its absolute t-ratio does
not exceed 1.645. For {cmd:ic(1)} and {cmd:ic(2)} a common (standard) sample size
is enforced across candidate lag orders, as in the source routine.

{phang}
{opt trim(#)} sets the trimming fraction that bounds the admissible break dates.
The default is {cmd:trim(0.10)}. It must lie strictly between 0 and 0.5.

{phang}
{opt seq:uential} selects the break dates by the two-step sequential procedure
of Narayan and Popp (2010, Eqs. 10-11) instead of the default full grid. Both
the break search and the reported test statistic are then based on the test
regressions exactly as written in the paper (Eq. 7 for M1, Eq. 8 for M2), in
which each break contributes a one-period impulse dummy, D(TB)(t) = 1 if
t = TB+1 and 0 otherwise, and a lagged level-shift dummy DU(t-1) = 1 if
t > TB+1 (plus a lagged trend-shift dummy DT(t-1) for M2). Step 1 chooses the
first break date to maximize the absolute t-value of the impulse-dummy
coefficient in the one-break regression; step 2 holds that date fixed and
chooses the second break date to maximize the absolute t-value of the second
impulse-dummy coefficient. The two dates must be at least 2 (M1) or 3 (M2)
periods apart, the spacing Narayan and Popp used when generating the critical
values, and the same trimming window applies to both steps. At every candidate
date the lag order is selected with the same {opt ic()} mechanics as in the
grid search, and the reported statistic is the t-ratio on y(t-1) from the
final two-break regression at its selected lag. The two breaks are reported in
chronological order, which need not be the order in which they were detected.
Because the default grid and the sequential procedure use different test
regressions and different selection criteria, their results can differ. See the
{help narayanp##remarks:Remarks} on the availability of this procedure in
other software.

{phang}
{opt sim:ul} selects the break dates with the simultaneous procedure of
Narayan and Popp (2010, Eq. 9). The test regressions are the paper-form
Eqs. 7-8 (as under {opt sequential}); all admissible pairs (TB1, TB2) with
TB1 + 2 <= TB2 for M1 and TB1 + 3 <= TB2 for M2 inside the trimming window
are searched, the lag order is selected for every pair with the same
mechanics as elsewhere ({opt ic()} or {opt bg}), and the pair maximizing the
F-statistic for the joint significance of the two impulse-dummy coefficients
is chosen. The unit-root statistic is the t-ratio on y(t-1) in the winning
regression, compared with the Table 3 critical values; the winning F value is
returned in {cmd:r(fstat)}. {opt simul} and {opt sequential} cannot be
combined. Like the default grid, {opt simul} evaluates on the order of T^2/2
candidate regressions, so it is slower than {opt sequential}; combined with
{opt bg} it can be slow on long series.

{phang}
{opt bg} selects the lag order by a Breusch-Godfrey general-to-specific
procedure instead of {opt ic()}. At every candidate break configuration (each
grid pair, or each candidate date under {opt sequential}), the walk starts at
{opt pmax()} and steps down: at each lag order the test regression of that
candidate is estimated on its full sample and its residuals are tested for
autocorrelation of orders 1 through {opt bglags()} with the Breusch-Godfrey
LM test (complete-case auxiliary regressions including the original
regressors, LM = n*R^2 against chi-squared, 5 percent level, matching
{cmd:estat bgodfrey, nomiss0}). While all orders are clean the lag is
reduced; at the first lag showing autocorrelation the walk returns to the
previous clean lag and selects it. If autocorrelation is present already at
{opt pmax()}, {opt pmax()} itself is used and a warning is printed for the
selected break dates. If no lag shows autocorrelation, lag 0 is selected.
With {opt bg} the {opt ic()} option is ignored. Because the walk runs at
every candidate, {opt bg} with the default grid can be slow on long series;
{opt bg} combined with {opt sequential} is fast.

{pstd}
Whatever the lag-selection method, the output always reports the minimum
Breusch-Godfrey p-value across the tested orders for the winning regression
(selected break dates at the selected lag), also stored in {cmd:r(bgminp)}.
This post-selection diagnostic shows at a glance whether residual
autocorrelation remains in the selected specification. When a method other
than {opt bg} was used and this minimum p-value falls below 0.05, a warning
is printed suggesting the {opt bg} option or a larger {opt pmax()}.

{phang}
{opt bgl:ags(#)} sets the highest autocorrelation order tested by the
Breusch-Godfrey procedure. When not specified, the default is chosen from the
data frequency so that the tested orders span roughly two years: 8 for
quarterly, 24 for monthly, 52 for weekly, 100 for daily, 2 for yearly, and 2
otherwise; the default is then capped at five times the conservative lag
bound floor(4*(T/100)^0.25) and floored at 1. An explicit {opt bglags(#)}
overrides the automatic choice and is never capped.
The horizon governs both the {opt bg} lag selection and the post-selection
diagnostic reported for every lag-selection method.

{phang}
{opt bgdf(#)} sets the minimum residual degrees of freedom an auxiliary
Breusch-Godfrey regression must have for its order to be tested. The
auxiliary regression for order m uses n-m observations and k+m parameters,
so its degrees of freedom are n-k-2m; orders with n-k-2m below {opt bgdf()}
are skipped, both in the lag-selection walk and in the reported minimum
p-value. This prevents spurious rejections from nearly saturated auxiliary
regressions when a large {opt pmax()} and a long horizon meet a short
sample. The default is {cmd:bgdf(20)}. The floor applies both to the
{opt bg} lag selection and to the post-selection diagnostic reported for
every lag-selection method.

{marker remarks}{...}
{title:Remarks}

{pstd}
The break locations {cmd:TB1} and {cmd:TB2} are reported as the observation
number of the last pre-break period (the level/trend shift takes effect at the
following observation) and, when the {helpb tsset} time variable permits, as the
corresponding calendar period. This matches the reporting convention of the
source routine.

{pstd}
Critical values are those tabulated in Narayan and Popp (2010, Table 3) and
depend on the model and on the full sample size {it:T}.

{pstd}
{bf:Break-date selection procedures and their availability.} Narayan and Popp
(2010) describe two procedures for locating the break dates, both of which
identify the timing of the breaks from the estimated break parameters rather
than from the unit-root statistic: a simultaneous grid search that maximizes
the joint F-statistic of the two impulse-dummy coefficients (their Eq. 9),
and a two-step sequential procedure that maximizes the absolute t-values of
the impulse-dummy coefficients one break at a time (their Eqs. 10-11). The
authors report that the two procedures give similar results and adopt the
sequential one for its lower computational cost. Both procedures are
available in {cmd:narayanp} through the {opt simul} and {opt sequential}
options. To the best of the author's knowledge, {cmd:narayanp} is at present
the only implementation of either procedure in Stata, GAUSS, or R: the GAUSS
{bf:tspdlib} routine {bf:ADF_2breaks} and the two-break routines of the R
package {bf:COINT} implement neither, as verified from their source code.

{pstd}
The default mode of {cmd:narayanp} instead reproduces, exactly and to
numerical precision, the grid search of the GAUSS {bf:tspdlib} routine, which
selects the break-date pair minimizing the ADF t-statistic itself in
regressions with contemporaneous step dummies. This selection rule follows a
long and respectable tradition in the endogenous-break literature (in the
spirit of Zivot and Andrews 1992), and it is the variant most users of the
GAUSS library will have in hand; it should be noted, however, that it is not
one of the two procedures described in Narayan and Popp (2010), whose
selection rules are based on the significance of the break parameters. The
default is retained for exact comparability with published tspdlib-based
results; users seeking the procedures of the original paper should use
{opt simul} or {opt sequential}.

{pstd}
{bf:Lag selection.} The t-sig, AIC, and SIC rules of {opt ic()} mirror the
GAUSS routine. The Breusch-Godfrey general-to-specific rule of the {opt bg}
option, together with its frequency-adaptive horizon, degrees-of-freedom
floor, and the post-selection BG diagnostic reported for every method, is an
addition of this implementation and appears neither in Narayan and Popp
(2010) nor in the GAUSS or R code bases mentioned above.

{pstd}
{bf:Replication in GAUSS.} {cmd:narayanp} follows the current GitHub source of
the tspdlib library, which is ahead of the tspdlib 3.0.0 release distributed
through the GAUSS package manager. The replication below applies to the
default grid search only; the {opt sequential} option has no counterpart in
tspdlib. The 3.0.0 release uses a different
specification (deterministic terms enter with a one-period lag, a one-observation
smaller effective sample, and different information-criterion formulas), so its
output will not match {cmd:narayanp}. To replicate {cmd:narayanp} results in
GAUSS: (1) download the current source archive from
{browse "https://github.com/aptech/tspdlib"} (Code > Download ZIP) or the copy at
{browse "https://www.eruygurakademi.com/datasets/narayanp/tspdlib-master.zip"};
(2) if an older tspdlib is already installed, remove or update it first so the
two versions do not conflict; (3) in GAUSS select Tools > Install Application
and point the installer to the downloaded zip; (4) load the library with
{cmd:library tspdlib;} and run {cmd:ADF_2breaks(y, model)}.

{marker examples}{...}
{title:Examples}

{pstd}Setup in Stata:{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta, clear}{p_end}

{pstd}
Each Stata command below is followed by a complete, runnable GAUSS program that
uses the current GitHub version of the tspdlib routine {cmd:ADF_2breaks} and
returns the same test statistic to at least 10 decimal places. The line
{cmd:ENFORCE_SAMPLE_SIZE = 1;} guards against sessions in which this tspdlib
global is not defined at library load, which otherwise raises an
"Undefined symbol" error.

{pstd}{bf:Example 1.} M1, break in level, default lag selection (t-sig, pmax 8):{p_end}
{phang2}{cmd:. narayanp y}{p_end}

{p 8 8 2}GAUSS:{p_end}
{phang2}{cmd:library tspdlib;}{p_end}
{phang2}{cmd:ENFORCE_SAMPLE_SIZE = 1;}{p_end}
{phang2}{cmd:y = loadd(getGAUSSHome() $+ "pkgs/tspdlib/examples/ts_examples.csv", "Y");}{p_end}
{phang2}{cmd:{ s, tb1, tb2, p, cv } = ADF_2breaks(y, 1);}{p_end}
{p 8 8 2}Result: test statistic -5.83291625149448, TB1 = 49 (0.441), TB2 = 87 (0.784), lags 3.{p_end}

{pstd}{bf:Example 2.} M2, break in level and slope:{p_end}
{phang2}{cmd:. narayanp y, model(2)}{p_end}

{p 8 8 2}GAUSS:{p_end}
{phang2}{cmd:library tspdlib;}{p_end}
{phang2}{cmd:ENFORCE_SAMPLE_SIZE = 1;}{p_end}
{phang2}{cmd:y = loadd(getGAUSSHome() $+ "pkgs/tspdlib/examples/ts_examples.csv", "Y");}{p_end}
{phang2}{cmd:{ s, tb1, tb2, p, cv } = ADF_2breaks(y, 2);}{p_end}
{p 8 8 2}Result: test statistic -5.29056381546383, TB1 = 49 (0.441), TB2 = 87 (0.784), lags 3.{p_end}

{pstd}{bf:Example 3.} Break in level, AIC lag selection:{p_end}
{phang2}{cmd:. narayanp y, ic(1)}{p_end}

{p 8 8 2}GAUSS:{p_end}
{phang2}{cmd:library tspdlib;}{p_end}
{phang2}{cmd:ENFORCE_SAMPLE_SIZE = 1;}{p_end}
{phang2}{cmd:y = loadd(getGAUSSHome() $+ "pkgs/tspdlib/examples/ts_examples.csv", "Y");}{p_end}
{phang2}{cmd:{ s, tb1, tb2, p, cv } = ADF_2breaks(y, 1, 8, 1);}{p_end}
{p 8 8 2}Result: test statistic -5.83291625149448, TB1 = 49 (0.441), TB2 = 87 (0.784), lags 3.{p_end}

{pstd}{bf:Example 4.} Break in level, SIC lag selection:{p_end}
{phang2}{cmd:. narayanp y, ic(2)}{p_end}

{p 8 8 2}GAUSS:{p_end}
{phang2}{cmd:library tspdlib;}{p_end}
{phang2}{cmd:ENFORCE_SAMPLE_SIZE = 1;}{p_end}
{phang2}{cmd:y = loadd(getGAUSSHome() $+ "pkgs/tspdlib/examples/ts_examples.csv", "Y");}{p_end}
{phang2}{cmd:{ s, tb1, tb2, p, cv } = ADF_2breaks(y, 1, 8, 2);}{p_end}
{p 8 8 2}Result: test statistic -5.26645494215392, TB1 = 49 (0.441), TB2 = 89 (0.802), lags 1.{p_end}

{pstd}{bf:Example 5.} Break in level and trend, SIC lag selection:{p_end}
{phang2}{cmd:. narayanp y, model(2) ic(2)}{p_end}

{p 8 8 2}GAUSS:{p_end}
{phang2}{cmd:library tspdlib;}{p_end}
{phang2}{cmd:ENFORCE_SAMPLE_SIZE = 1;}{p_end}
{phang2}{cmd:y = loadd(getGAUSSHome() $+ "pkgs/tspdlib/examples/ts_examples.csv", "Y");}{p_end}
{phang2}{cmd:{ s, tb1, tb2, p, cv } = ADF_2breaks(y, 2, 8, 2);}{p_end}
{p 8 8 2}Result: test statistic -4.95065916935478, TB1 = 24 (0.216), TB2 = 46 (0.414), lags 0.{p_end}

{pstd}{bf:Example 6.} Sequential break selection (paper procedure, Eqs. 10-11):{p_end}
{phang2}{cmd:. narayanp y, sequential}{p_end}

{p 8 8 2}Result: test statistic -4.04092343355651, TB1 = 76 (0.685), TB2 = 87 (0.784), lags 3. The sequential procedure has no counterpart in tspdlib, so no GAUSS replication block can be given; the numbers differ from Example 1 because the sequential option uses the paper-form regressions and a different selection criterion.{p_end}

{pstd}{bf:Example 7.} Breusch-Godfrey lag selection (grid and sequential):{p_end}
{phang2}{cmd:. narayanp y, bg}{p_end}
{phang2}{cmd:. narayanp y, model(2) sequential bg}{p_end}

{p 8 8 2}Result (first command; monthly data gives an automatic horizon of
24, capped at 20 for this sample of T = 111, so orders 1-20 are tested): test
statistic -5.64623029815526, TB1 = 46 (0.414), TB2 = 87 (0.784), lags 3, BG
min p-value 0.2610. With {cmd:bglags(8)} the first command
gives -5.65505254647156 with TB1 = 48, TB2 = 87, lags 3. The BG procedure has
no counterpart in tspdlib or in the paper; it is an additional lag-selection
rule applied to the same test regressions.{p_end}

{pstd}{bf:Example 8.} Simultaneous procedure (paper, Eq. 9):{p_end}
{phang2}{cmd:. narayanp y, simul}{p_end}
{phang2}{cmd:. narayanp y, model(2) simul}{p_end}
{phang2}{cmd:. narayanp y, simul bg}{p_end}

{p 8 8 2}Result (first command): test statistic -4.04092343355651, TB1 = 76
(0.685), TB2 = 87 (0.784), lags 3, F = 9.037 ({cmd:r(fstat)}). On this data
set the simultaneous and sequential procedures select the same break dates in
every configuration, in line with the remark of Narayan and Popp (2010) that
the two procedures give similar results.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:narayanp} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(tstat)}}ADF test statistic at the selected break dates{p_end}
{synopt:{cmd:r(tb1)}}first break location (observation number){p_end}
{synopt:{cmd:r(tb2)}}second break location (observation number){p_end}
{synopt:{cmd:r(frac1)}}first break fraction, tb1/T{p_end}
{synopt:{cmd:r(frac2)}}second break fraction, tb2/T{p_end}
{synopt:{cmd:r(lags)}}selected number of lags of D.y{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of the tested series{p_end}
{synopt:{cmd:r(model)}}selected model{p_end}
{synopt:{cmd:r(ic)}}selected information criterion{p_end}
{synopt:{cmd:r(breaksearch)}}{cmd:grid}, {cmd:sequential}, or {cmd:simultaneous}{p_end}
{synopt:{cmd:r(fstat)}}winning joint impulse F statistic ({opt simul} only){p_end}
{synopt:{cmd:r(lagsel)}}{cmd:tsig}, {cmd:aic}, {cmd:sic}, or {cmd:bg}{p_end}
{synopt:{cmd:r(bgminp)}}minimum BG p-value at the winning regression{p_end}
{synopt:{cmd:r(bglags)}}highest BG order tested (after automatic resolution and cap){p_end}
{synopt:{cmd:r(bgdf)}}degrees-of-freedom floor for BG auxiliary regressions{p_end}

{marker references}{...}
{title:References}

{phang}
Narayan, P. K., and S. Popp. 2010. A new unit root test with two structural
breaks in level and slope at unknown time. {it:Journal of Applied Statistics}
37 (9): 1425-1438.

{phang}
Perron, P. 1989. The great crash, the oil price shock, and the unit root
hypothesis. {it:Econometrica} 57 (6): 1361-1401.

{phang}
Schmidt, P., and P. C. B. Phillips. 1992. LM tests for a unit root in the
presence of deterministic trends. {it:Oxford Bulletin of Economics and
Statistics} 54 (3): 257-287.

{phang}
Nazlioglu, S. tspdlib: GAUSS time series and panel data methods. Source code
available at {browse "https://github.com/aptech/tspdlib":https://github.com/aptech/tspdlib}.

{phang}
Zivot, E., and D. W. K. Andrews. 1992. Further evidence on the great crash,
the oil-price shock, and the unit-root hypothesis. {it:Journal of Business and
Economic Statistics} 10 (3): 251-270.

{title:Author}

{pstd}H. Ozan Eruygur{p_end}
{pstd}AHBV University, Ankara, Turkiye.{p_end}
{pstd}Department of Economics{p_end}
{pstd}{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{p_end}
{pstd}eruygur@gmail.com{p_end}

{pstd}Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{p_end}
{pstd}{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{p_end}
{pstd}eruygurakademi@gmail.com{p_end}

{pstd}{bf:narayanp} v1.0.0 -- July 2026{p_end}

{pstd}
{bf:narayanp} is a Stata/Mata port of the GAUSS routine {bf:ADF_2breaks} from
the TSPDLIB library by Saban Nazlioglu, extended with the {opt simul} and
{opt sequential} break-date selection procedures of Narayan and Popp (2010,
Eqs. 9-11) and with the Breusch-Godfrey-based lag selection of the {opt bg}
option, all of which are contributions of this implementation.

{pstd}{bf:Please cite as:}{p_end}

{pstd}
Eruygur, H. O. 2026. {bf:narayanp}: Narayan-Popp (2010) unit root test with two
structural breaks. Stata package version 1.0.0. Available from:
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}.{p_end}
