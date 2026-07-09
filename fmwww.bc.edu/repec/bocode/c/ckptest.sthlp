{smcl}
{* *! version 1.0.0  07jul2026}{...}
{viewerjumpto "Syntax" "ckptest##syntax"}{...}
{viewerjumpto "Description" "ckptest##description"}{...}
{viewerjumpto "Options" "ckptest##options"}{...}
{viewerjumpto "Remarks" "ckptest##remarks"}{...}
{viewerjumpto "Examples" "ckptest##examples"}{...}
{viewerjumpto "Stored results" "ckptest##results"}{...}
{viewerjumpto "References" "ckptest##references"}{...}
{title:Title}

{phang}
{bf:ckptest} {hline 2} CKP unit root tests up to 5 unknown break points
(Carrion-i-Silvestre, Kim, and Perron, 2009)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ckptest}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt m:odel(spec)}}deterministic specification: {opt const}
(constant, no breaks), {opt trend} (linear trend, no breaks), {opt slope}
(Model I) or {opt break} (Model II); default is
{cmd:model(break)}{p_end}
{synopt:{opt b:reaks(#)}}number of unknown structural breaks, 1 to 5;
default is {cmd:breaks(1)}{p_end}
{synopt:{opt breakd:ates(numlist)}}known break dates, given either as values
of the time variable or as observation numbers (positions within the
estimation sample); strictly increasing, up to 5; overrides
{opt breaks()}{p_end}

{syntab:Break date estimation}
{synopt:{opt meth:od(spec)}}break date estimation method for unknown breaks:
{opt dp} (Bai-Perron type dynamic programming with Perron-Qu restrictions,
GAUSS estimation=1, handles 1 to 5 unknown breaks) or {opt brute}
(exhaustive grid search over the GLS-SSR, GAUSS estimation=0, up to 3
unknown breaks); default is {cmd:method(dp)}{p_end}
{synopt:{opt max:iter(#)}}maximum number of iterations of the dynamic
programming method {cmd:dp}; default is {cmd:maxiter(100)}{p_end}

{syntab:Long-run variance}
{synopt:{opt p:enalty(spec)}}information criterion for the lag order of the
autoregressive spectral density estimator: {opt maic} or {opt bic}; default is
{cmd:penalty(maic)}{p_end}
{synopt:{opt km:ax(#)}}maximum lag order; default is {cmd:kmax(4)}{p_end}
{synopt:{opt kmi:n(#)}}minimum lag order; default is {cmd:kmin(0)}{p_end}

{syntab:Reporting}
{synopt:{opt bg}}select the lag order of the spectral AR regression by
Breusch-Godfrey general-to-specific search instead of {opt penalty()}{p_end}
{synopt:{opt bgl:ags(#)}}highest Breusch-Godfrey order tested (the horizon);
default is an automatic frequency-based choice{p_end}
{synopt:{opt bgd:f(#)}}skip Breusch-Godfrey orders whose auxiliary regression
has fewer than # residual degrees of freedom; default is {cmd:bgdf(20)}{p_end}
{synopt:{opt nopr:int}}suppress the output table{p_end}

{syntab:Pretest (Perron and Yabu 2009)}
{synopt:{opt nopre:test}}suppress the Perron-Yabu (2009) test for a break in
trend, which is run and displayed by default before the unit root tests{p_end}
{synopt:{opt pretesta:ll}}display the full pretest panel, adding the lag and
trimming settings and the estimated break date{p_end}
{synoptline}
{p 4 6 2}
The data must be {helpb tsset} with a time variable and contain no gaps in the
estimation sample. {it:varname} may contain time-series operators
({cmd:D.}, {cmd:L.}, {cmd:F.}, {cmd:S.}); the operated series is resolved via
{helpb tsrevar} before estimation.


{marker description}{...}
{title:Description}

{pstd}
{cmd:ckptest} computes the quasi-GLS-detrended unit root tests of
Carrion-i-Silvestre, Kim, and Perron (2009), henceforth CKP, which allow for
multiple structural breaks in the trend function under {it:both} the null
hypothesis of a unit root and the alternative hypothesis of stationarity.
The data generating process is y(t) = d(t) + u(t) with
u(t) = alpha*u(t-1) + v(t); the null hypothesis is alpha = 1. The
distinguishing capability of the command is the estimation of up to
{bf:5 unknown break dates} with the default dynamic programming method,
{cmd:method(dp)}.

{pstd}
The deterministic component d(t) always contains a constant and a linear
trend; the break terms are built from the two dummy variables of the paper:
for a break at date Tj, DUj = 1 after the break and 0 before (level shift),
and DTj = t - Tj after the break and 0 before (slope change). The
{opt model()} option selects among the following specifications, where
u(t) = a*u(t-1) + v(t) and the null hypothesis is a = 1:

{phang2}{cmd:model(const)} - constant only, no breaks:{p_end}
{p 12 12 2}y(t) = c + u(t){p_end}

{phang2}{cmd:model(trend)} - constant and linear trend, no breaks:{p_end}
{p 12 12 2}y(t) = c + b*t + u(t){p_end}

{phang2}{cmd:model(slope)} - the m breaks shift the slope of the trend
only (Model I in CKP):{p_end}
{p 12 12 2}y(t) = c + b*t + g1*DT1 + ... + gm*DTm + u(t){p_end}

{phang2}{cmd:model(break)} - the m breaks shift both the level and the
slope of the trend (Model II in CKP); the default:{p_end}
{p 12 12 2}y(t) = c + b*t + th1*DU1 + g1*DT1 + ... + thm*DUm + gm*DTm + u(t){p_end}

{pstd}
All models are of the additive outlier (AO) type of Perron (1989): the
breaks enter the trend function, not the dynamics.

{pstd}
The noncentrality parameter c-bar is the value for which the local
asymptotic power of the tests equals 50 percent against the Gaussian power
envelope; it depends on the number of breaks and the break fractions (Table
1 of the paper for one and two breaks). Both c-bar and the 1, 2.5, 5 and 10
percent critical values are evaluated from the response surfaces estimated
by the authors for up to 5 breaks and distributed with the GAUSS code.

{pstd}
Unknown break dates are estimated by global minimization of the sum of
squared residuals of the GLS-detrended regression (eq. 12 of the paper).
Two search methods are available: the iterative dynamic programming
procedure of Section 5.2 - Bai and Perron (2003) dating combined with the
restricted estimation of Perron and Qu (2006) under quasi-differencing -
which is the default ({cmd:method(dp)}) and the only method available for 4
or 5 unknown breaks, and the exhaustive grid search ({cmd:method(brute)}),
which the original code provides for up to 3 unknown breaks. By Proposition
2 of the paper, when breaks are present the tests evaluated at these
estimates have the same limit distributions as in the known break date
case. Known break dates can instead be supplied directly with
{opt breakdates()}.

{pstd}
The unit root null hypothesis is rejected for values of the statistics
{it:below} the critical value (all seven tests are left-tailed in the metric
reported).


{marker tests}{...}
{title:Reported test statistics}

{pstd}
All seven statistics are computed on the quasi-GLS detrended series at
alpha-bar = 1 + c-bar/T, and for all of them the null is rejected for
values {it:below} the critical value. The long-run variance is estimated by the autoregressive
spectral density estimator at frequency zero (eq. 6 of the paper), with the
lag order selected by the MAIC of Ng and Perron (2001) computed on
OLS-detrended data as in Perron and Qu (2007), or by the BIC.

{phang2}{cmd:PT} - The feasible point optimal statistic of Elliott,
Rothenberg and Stock (1996) extended to multiple breaks (eq. 5). It is the
(feasible) most powerful test against the local alternative a = 1 +
c-bar/T, so its local asymptotic power lies close to the Gaussian power
envelope. H0: unit root.{p_end}

{phang2}{cmd:MPT} - The modified feasible point optimal statistic of Ng and
Perron (2001). It has the same limit distribution as PT but is built from
sample moments of the detrended series, which gives it better finite-sample
size when combined with the MAIC. H0: unit root.{p_end}

{phang2}{cmd:ADF} - The ADF t statistic computed on the GLS-detrended
series (the ADF-GLS of Elliott, Rothenberg and Stock 1996, with break
dummies in the detrending step). Familiar and easy to communicate; its
finite-sample size depends more heavily on the lag selection than that of
the M-tests. H0: unit root.{p_end}

{phang2}{cmd:ZA} - The (unmodified) Phillips Z-alpha-type coefficient
statistic on the GLS-detrended series. Perron and Ng (1996) show that this
class of statistics suffers from severe size distortions when the errors
contain a large negative moving average component; it is reported for
completeness and comparison, and is {it:not} recommended as the decision
statistic. H0: unit root.{p_end}

{phang2}{cmd:MZA}, {cmd:MSB}, {cmd:MZT} - The M-class statistics of Stock
(1999) as analyzed in Ng and Perron (2001), extended to multiple breaks
(eqs. 9-11). MZA is the modified version of ZA and MZT is the modified t
statistic (MZT = MZA x MSB); for these two, as for ADF and ZA, positive
values point toward an explosive root and rejection occurs in the negative
tail. MSB is different: it is a modified Sargan-Bhargava statistic, not a
t-type statistic - nonnegative by construction, it tends to zero under
stationarity and diverges under an explosive root, so rejection is for
small values (still below its critical value, which is positive). Combined with GLS detrending and MAIC lag selection, the M-tests
have far smaller size distortions than ZA (and than the standard ADF) under
serially correlated errors, in particular with negative MA components,
while retaining power close to the envelope. H0: unit root for all
three.{p_end}

{pstd}
Practical guidance, following Ng and Perron (2001): use {cmd:MZT} (or
{cmd:MZA}) together with {cmd:MPT} as the headline statistics; {cmd:PT} and
{cmd:ADF} are informative complements, and agreement across the M-tests
strengthens the conclusion. Treat {cmd:ZA} with caution for the reason
above. Note also that when no break is actually present the estimated break
fractions do not converge and the reported tests can over-reject (Section 6
of the paper); the pretest remedy of Section 7 - the Perron and Yabu (2009)
test for a break in trend - is run by default before the unit root tests
and can be suppressed with the {opt nopretest} option
(see {help ckptest##pretest:Pretest} below).


{marker pretest}{...}
{title:The Perron-Yabu (2009) pretest for a break in trend}

{pstd}
{cmd:ckptest} runs, by default and before the unit root tests, the test of
Perron and Yabu (2009,
Journal of Business and Economic Statistics 27, 369-396) for a structural
change in the trend function of a series at an unknown date. This is the
procedure recommended by Carrion-i-Silvestre, Kim, and Perron (2009) in
Section 7 of their paper for the case where a break need not occur. The null
hypothesis is that there is no break in the trend function; the alternative
is that there is one break at an unknown date. The distinctive feature of
the test is that it is valid whether u(t) is stationary or has a unit
root, so no prior knowledge about the order of integration is required.

{pstd}
The pretest asks one question: is there a break in the trend function?
The question comes in two forms, and the form is chosen automatically from
the {opt model()} option of the main command - no separate option is
needed, and the output panel states which form was run. With a single
break at date TB (DU = 1 after the break and 0 before; DT = t - TB after
the break and 0 before):

{phang2}{cmd:model(slope)} - the pretest asks: is there a break in the
slope of the trend?{p_end}
{p 12 12 2}y(t) = a0 + b0*t + b1*DT + u(t){p_end}

{phang2}{cmd:model(break)} - the pretest asks: is there a break in the
level and slope of the trend?{p_end}
{p 12 12 2}y(t) = a0 + a1*DU + b0*t + b1*DT + u(t){p_end}

{pstd}
The implemented pretest tests the null of no break against {it:one} break
at an unknown date. Section 5 of Perron and Yabu (2009) extends the theory
to multiple breaks, but the Exp statistic then requires evaluating the
Wald test over a number of break-date combinations of order T^m, which the
authors describe as prohibitive beyond two breaks; the program they
distribute, and hence {cmd:ckptest}, implements the single-break test.
Rejecting the no-break null is what justifies moving to the break unit
root tests, whatever the number of breaks specified in {opt breaks()}. For
testing and determining the number of {it:multiple} breaks in trend under
the same framework - valid whether u(t) is stationary or has a unit root -
see the sequential procedure of Kejriwal and Perron (2010).


{pstd}
The statistic is built as follows. For every candidate break date TB in the
trimmed range [eps*T, (1-eps)*T], the sum of the autoregressive
coefficients of u(t) is estimated from an autoregression on
the OLS-detrended series, a bias correction is applied, and the estimate is
replaced by exactly 1 whenever it falls in a T^(-1/2) neighborhood of 1
(the superefficient estimate). The data are then quasi-differenced at this
value and the Wald statistic for the null of no structural change in the
break coefficients is computed from the feasible GLS regression. The Wald
statistics are aggregated over the candidate dates with the Exp functional
of Andrews and Ploberger (1994), giving the statistic reported as
{bf:Exp-W(FS)}. Rejection is for values ABOVE the critical value; the 10, 5
and 1 percent critical values displayed are the values tabulated by Perron
and Yabu (2009) for the trimming used. The break date reported in the
panel is the OLS minimum-SSR estimate over the same trimmed range. The
implementation is a line-by-line port of the authors' GAUSS program
qfgls.prg (version 2, March 2009), preserved exactly, and is run with the
settings of that program: BIC lag selection, trimming eps=0.15 and maximum
lag order int(12*(T/100)^(1/4)).

{pstd}
{bf:How to use the pretest} - the Section 7 procedure of Carrion-i-Silvestre,
Kim, and Perron (2009), step by step:

{phang2}1. Look at {bf:Exp-W(FS)} in the pretest panel and compare it with
the critical values: the null of no break in trend is rejected for values
{it:above} the critical value (the stars mark rejection at the 10, 5 and 1
percent levels).{p_end}

{phang2}2. {bf:If the pretest rejects}: there is evidence of a break in the
trend. Proceed with the break unit root tests below the panel
({cmd:model(break)} or {cmd:model(slope)}) and read the unit root decision
from PT, MPT and the M-class statistics; do not base it on ADF, which
retains liberal size distortions even with the pretest (Section 7.1 of the
paper).{p_end}

{phang2}3. {bf:If the pretest does not reject}: there is no evidence of a
trend break. Do not base the unit root decision on the break tests - with
no break their estimated break fractions do not converge and they can
over-reject (Section 6 of the paper). Use the no-break tests instead:
{cmd:model(trend)}, or {cmd:model(const)} if no trend is present.{p_end}


{marker bglag}{...}
{title:Lag selection controlling serial correlation (a general-to-specific algorithm)}

{pstd}
The lag order k of the spectral AR regression - the regression whose
residuals produce the spectral density estimate s2 that all seven test
statistics depend on - is selected by MAIC by default, or by BIC with
{cmd:penalty(bic)}. The {opt bg} option replaces the information criterion
with a general-to-specific algorithm that selects the smallest lag order
whose residuals are free of serial correlation, judged by the
Breusch-Godfrey LM test:

{phang2}1. Start at {opt kmax()}, the highest lag order of the spectral
regression, and test its residuals with Breusch-Godfrey at every order
from 1 up to the horizon (see {opt bglags()} below). The regression is
clean if the minimum p-value over these orders is at or above 0.05.{p_end}

{phang2}2. If even {opt kmax()} is not clean, {opt kmax()} is used and a
warning is printed: consider increasing {opt kmax()}.{p_end}

{phang2}3. Otherwise walk downward one lag at a time, repeating the test.
At the first lag order that shows autocorrelation, stop and select the
previous (clean) lag order.{p_end}

{pstd}
The Breusch-Godfrey statistic is computed as by {cmd:estat bgodfrey} with
the {cmd:nomiss0} option: the auxiliary regression for order m drops the
first m observations, has no constant (the spectral regression has none,
so the uncentered R-squared is used), and LM = (n-m)*R2 ~ chi2(m). Orders
whose auxiliary regression has fewer than {opt bgdf(#)} residual degrees
of freedom (df = n - k - 2m for order m) are skipped, to prevent spurious
rejections from near-saturated auxiliary regressions; the default is
{cmd:bgdf(20)}.

{pstd}
Two distinct maximum lags are involved and should not be confused:
{opt kmax()} is the highest lag of the spectral regression itself (where
the downward walk starts), while {opt bglags(#)} is the horizon of the
Breusch-Godfrey test - the highest order of residual autocorrelation
tested. The default horizon is an automatic choice of about two years of
orders by data frequency - 2 yearly, 8 quarterly, 24 monthly, 52 weekly,
100 daily, 2 otherwise - capped at 5*floor(4*(T/100)^(1/4)); an explicit
{opt bglags(#)} overrides the automatic choice and is never capped.

{pstd}
Whatever the selection method (MAIC, BIC or {opt bg}), the minimum
Breusch-Godfrey p-value at the selected lag is always computed and
reported in the header panel as a residual diagnostic, with a note when it
falls below 0.05; it is also saved in {cmd:r(bgminp)}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(spec)} sets the deterministic specification. {opt const} is
the constant-only case with no breaks (c-bar fixed at -7); {opt trend} is
the linear trend case with no breaks (c-bar fixed at -13.5); {opt slope} is
Model I in CKP, breaks in the slope of the trend only; {opt break} is
Model II in CKP, simultaneous breaks in the level and the slope of the
trend. The numeric codes 0, 1, 2 and 3 of the GAUSS program are also
accepted as input. Default is {cmd:model(break)}.

{phang}
{opt breaks(#)} sets the number of unknown structural breaks (1 to 5) to be
estimated. With {cmd:method(brute)} the original GAUSS code implements the
grid search for up to 3 unknown breaks only; 4 or 5 unknown breaks require
{cmd:method(dp)}, the default. Ignored when {opt breakdates()} is
specified.

{phang}
{opt breakdates(numlist)} supplies known break dates (up to 5, strictly
increasing). Each entry is first matched against the values of the time
variable within the estimation sample; if it does not match, an integer
between 1 and T is interpreted as an observation number, i.e. the position
of the break within the estimation sample (for data with t = 1,...,T the
two readings coincide). Each break marks the last observation of the
corresponding regime, following the timing convention of the GAUSS code.
With known dates the statistics are computed directly; {opt method()} is
not used.

{dlgtab:Break date estimation}

{phang}
{opt method(spec)} chooses how unknown break dates are estimated.
{opt dp} (the default) uses the iterative dynamic programming procedure of
Section 5.2 of the paper: OLS dating (Bai-Perron), iterated GLS dating, and
iterated restricted estimation in the sense of Perron and Qu (2006), with a
trimming parameter of 0.10 hardcoded in the source; it handles 1 to 5
unknown breaks. {opt brute} evaluates the GLS-SSR over the full grid of
admissible break date combinations (candidates run from t=3 to T-3 with a
minimum distance of 2 between consecutive breaks), exactly as in the GAUSS
brute-force procedure, which is written for up to 3 unknown breaks.

{phang}
{opt maxiter(#)} sets the maximum number of iterations for the GLS dating
loop and for the restricted estimation loop of {cmd:method(dp)} (GAUSS
estimation[2]). The inner iteration limit of 10 inside the restricted
estimation procedure is hardcoded in the source and is not affected by this
option. Default is {cmd:maxiter(100)}, following the tspdlib control
structure; the authors' own example uses 20.

{dlgtab:Long-run variance}

{phang}
{opt penalty(spec)}, {opt kmax(#)} and {opt kmin(#)} control the lag order of
the autoregressive estimate of the spectral density at frequency zero,
selected on OLS-detrended data as recommended by Perron and Qu (2007).
{opt maic} is the modified AIC of Ng and Perron (2001); {opt bic} is the
Bayesian information criterion. Defaults are {cmd:penalty(maic)},
{cmd:kmax(4)}, {cmd:kmin(0)}, following the tspdlib control structure.

{dlgtab:Reporting}

{phang}
{opt noprint} suppresses the output table; results remain in {cmd:r()}.


{dlgtab:Pretest}

{phang}
{opt nopretest} suppresses the Perron-Yabu (2009) Exp-W(FS) test for a
break in trend, which by default is run before the unit root tests and
displayed in a separate panel, with the settings of the authors' program
qfgls.prg (BIC, trimming 0.15). See {help ckptest##pretest:Pretest} above.

{phang}
{opt pretestall} displays the full pretest panel: in addition to the
Exp-W(FS) statistic and its critical values, the lag and trimming settings
and the estimated break date (the OLS minimum-SSR estimate, also saved in
{cmd:r(pybreakdate)}) are shown.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:ckptest} makes two main contributions:

{phang2}1. The Perron-Yabu (2009) {bf:pretest} for a break in trend, run
and reported {bf:by default} before the unit root tests - the Section 7
procedure of Carrion-i-Silvestre, Kim, and Perron (2009); see
{help ckptest##pretest:Pretest} above.{p_end}

{phang2}2. A {bf:general-to-specific lag selection algorithm} ({opt bg})
that selects the lag order of the spectral AR regression by controlling
residual serial correlation with the Breusch-Godfrey test; see
{help ckptest##bglag:Lag selection controlling serial correlation}
above.{p_end}

{pstd}
In addition, {cmd:ckptest} estimates up to {bf:5 unknown structural breaks},
by default with the dynamic programming method ({cmd:method(dp)}). This
capability comes from the original GAUSS program of Carrion-i-Silvestre,
Kim, and Perron (2009), both of whose break-date estimation paths are
implemented.

{pstd}
Critical values at the 1, 2.5, 5 and 10 percent levels are computed from the
response surfaces distributed with the GAUSS code, evaluated at the estimated
(or supplied) break fractions and the associated c-bar, exactly as in the
authors' own example program. The response surface reproduces the published
Tables 2A-2D of the paper at the tabulated break fractions. For
{cmd:model(const)} and {cmd:model(trend)} the surfaces are evaluated at zero
break fractions with the fixed c-bar of the model, which corresponds to the
no-break limit of the surfaces.

{pstd}
Following a quirk that is present in the original GAUSS dynamic programming procedure
and preserved here for exact replication, in {cmd:method(dp)} the
c-bar used in the final statistics is the one obtained in the GLS dating
loop; it is not recomputed after the restricted estimation stage updates the
break dates.

{pstd}
One documented deviation from the source: in the unknown-break grid search
the GAUSS code initializes the incumbent minimum with y'y, which is not an
upper bound of the quasi-differenced SSR when the series is strongly
stationary; in that case the original code stops with a singular matrix
error. {cmd:ckptest} initializes the incumbent with the largest double
instead, which returns the identical break dates and statistics whenever the
GAUSS code runs, and a valid result where the GAUSS code fails.

{pstd}
The brute-force search cost grows quickly with the number of breaks: with
T=200, 2 unknown breaks require roughly 18,000 GLS regressions and 3 unknown
breaks roughly 1.1 million. The dynamic programming method is much faster
for 2 or more breaks and is the only option for 4 or 5 unknown breaks.

{pstd}
{cmd:ckptest} requires the estimation sample to be a contiguous time series
without gaps and does not allow panel data.



{marker examples}{...}
{title:Examples}

{pstd}Setup (the dataset is hosted online and is saved tsset with monthly
time variable {cmd:t}, 1980m1-1989m3; the series {cmd:y} has T=111
observations):{p_end}
{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta, clear}{p_end}

{pstd}Five unknown breaks with the dynamic programming method (dp, which is
the default) - the distinguishing capability of the command:{p_end}
{phang2}{cmd:. ckptest y, breaks(5) maxiter(20)}{p_end}
{phang2}{cmd:. ckptest y, model(slope) breaks(5) maxiter(20)}{p_end}
{phang2}{cmd:. ckptest D.y, breaks(5) maxiter(20)}{p_end}

{pstd}Five known break dates (values of the time variable or observation
numbers):{p_end}
{phang2}{cmd:. ckptest y, breakdates(11 22 47 76 93)}{p_end}

{pstd}One and two unknown breaks with the defaults:{p_end}
{phang2}{cmd:. ckptest y}{p_end}
{phang2}{cmd:. ckptest y, breaks(2) maxiter(20)}{p_end}

{pstd}The brute-force grid search of the original code (up to 3 unknown
breaks):{p_end}
{phang2}{cmd:. ckptest y, breaks(1) method(brute)}{p_end}

{pstd}Known break dates - the dates identified by the Narayan-Popp test on
the same series - given either as values of the (monthly) time variable or
as observation numbers:{p_end}
{phang2}{cmd:. ckptest y, breakdates(tm(1984m1) tm(1987m3))}{p_end}
{phang2}{cmd:. ckptest y, breakdates(49 87)}{p_end}

{pstd}No-break benchmarks:{p_end}
{phang2}{cmd:. ckptest y, model(trend)}{p_end}
{phang2}{cmd:. ckptest y, model(const)}{p_end}

{pstd}{bf:The Perron-Yabu (2009) pretest for a break in trend}{p_end}

{pstd}The pretest runs by default before the unit root tests, in a
separate panel (see {help ckptest##pretest:the pretest section} for the
test and the decision rule); suppress it with {opt nopretest}:{p_end}
{phang2}{cmd:. ckptest y, breaks(2) maxiter(20)}{p_end}
{phang2}{cmd:. ckptest y, nopretest}{p_end}


{marker gaussrep}{...}
{title:GAUSS replications}

{pstd}
Every example below pairs a {cmd:ckptest} call (with the expected values to
12 decimals) with a standalone GAUSS program that reproduces it. The
replications are organized in two parts, one for each of the two original
GAUSS programs.

{dlgtab:Part 1: the unit root tests - Carrion-i-Silvestre, Kim, and Perron (2009)}

{pstd}
The GAUSS code used in this part is {bf:msbur.src}, the original program
written by the authors of the test (Carrion-i-Silvestre, Kim, and Perron
2009) and made available on the internet by them. The five-break examples
come first: estimating up to 5 unknown breaks is the distinguishing
capability of the command.

{pstd}{bf:Example 1}{p_end}
{pstd}Five unknown breaks in level and slope with the dynamic programming method (dp, which is the default) - the distinguishing capability of the command; the grid search of the original code stops at 3:{p_end}
{phang2}{cmd:. ckptest y, breaks(5) maxiter(20)}{p_end}
{p 8 8 2}expected: pt=16.061984740414  mpt=14.912789204487  mzt=-3.865730078908  tb=(11,22,47,76,93)  cbar=-29.843960944437  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|5, 0, 4, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 2}{p_end}
{pstd}Five unknown breaks in the trend slope only (Model I):{p_end}
{phang2}{cmd:. ckptest y, model(slope) breaks(5) maxiter(20)}{p_end}
{p 8 8 2}expected: pt=18.538789954171  mpt=16.753054834733  mzt=-3.642652310303  tb=(22,38,49,78,93)  cbar=-29.843960944437  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 2|1|5, 0, 4, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 3}{p_end}
{pstd}Five unknown breaks with BIC lag selection:{p_end}
{phang2}{cmd:. ckptest y, breaks(5) penalty(bic) kmax(8) maxiter(20)}{p_end}
{p 8 8 2}expected: identical to Example 1 (BIC also selects lags=0 here){p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|5, 1, 8, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 4}{p_end}
{pstd}The same five dates supplied as known breaks. Note that c-bar differs from Example 1: with known dates c-bar is evaluated at the supplied fractions, whereas method(dp) keeps the c-bar of its GLS dating loop (a quirk of the original code preserved for exact replication; see Remarks):{p_end}
{phang2}{cmd:. ckptest y, breakdates(11 22 47 76 93)}{p_end}
{p 8 8 2}expected: pt=15.606771696514  mpt=14.505321127788  mzt=-3.857926005746  cbar=-29.369543956212  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|0|11|22|47|76|93, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 5}{p_end}
{pstd}Five unknown breaks on an operated series (first difference, T=110):{p_end}
{phang2}{cmd:. ckptest D.y, breaks(5) maxiter(20)}{p_end}
{p 8 8 2}expected: pt=9.849072471824  mpt=8.846825652907  mzt=-4.658866714726  tb=(21,32,75,86,97)  cbar=-27.713571430176  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:y = trimr(y,1,0) - trimr(lagn(y,1),1,0);}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|5, 0, 4, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 6}{p_end}
{pstd}One unknown break with the defaults (model(break), breaks(1), method(dp)):{p_end}
{phang2}{cmd:. ckptest y, maxiter(20)}{p_end}
{p 8 8 2}expected: pt=8.350829884312  mpt=8.053921184408  adf=-3.231029255781  za=-20.124038087879  mza=-18.278778491839  msb=0.160555711616  mzt=-2.934762288223  tb=76  cbar=-16.540334475318  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|1, 0, 4, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 7}{p_end}
{pstd}The same configuration with the brute-force grid search (shown to illustrate method(brute); on this series both methods find tb=76, so all numbers are identical to Example 6):{p_end}
{phang2}{cmd:. ckptest y, breaks(1) method(brute)}{p_end}
{p 8 8 2}expected: identical to Example 6{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|1, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 8}{p_end}
{phang2}{cmd:. ckptest y, breaks(2) maxiter(20)}{p_end}
{p 8 8 2}expected: pt=7.124199022752  mzt=-3.436305254807  tb=(76,93)  cbar=-18.231324349742  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|2, 0, 4, 0, 1|20);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 9}{p_end}
{pstd}Two unknown breaks with the grid search: the two methods can select different dates (global min-SSR grid versus the iterated dynamic programming procedure):{p_end}
{phang2}{cmd:. ckptest y, breaks(2) method(brute)}{p_end}
{p 8 8 2}expected: pt=7.825678390094  mzt=-3.299765521343  tb=(76,94)  cbar=-18.231324349742  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|1|2, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 10}{p_end}
{pstd}Known break dates - the dates identified by the Narayan-Popp test on the same series, given as observation numbers:{p_end}
{phang2}{cmd:. ckptest y, breakdates(49 87)}{p_end}
{p 8 8 2}expected: pt=7.954403297919  mpt=7.930348369119  adf=-4.363921725011  za=-32.976521485471  mza=-28.032771431438  msb=0.132334204107  mzt=-3.709694496304  cbar=-20.748316533660  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|0|49|87, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 11}{p_end}
{pstd}No-break benchmark with a linear trend:{p_end}
{phang2}{cmd:. ckptest y, model(trend)}{p_end}
{p 8 8 2}expected: pt=5.602655888897  adf=-3.099809892801  mzt=-2.848430153196  cbar=-13.5  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 1, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{pstd}{bf:Example 12}{p_end}
{pstd}Operated series with a known break given in time-variable units (t=49 is position 48 of the D.y sample, hence 48 on the GAUSS side):{p_end}
{phang2}{cmd:. ckptest D.y, breakdates(49)}{p_end}
{p 8 8 2}expected: pt=3.294105560179  mzt=-5.163715158161  cbar=-18.075104832586  lags=0{p_end}

{pstd}
To reproduce the same numbers in the original GAUSS code, create a folder
named {bf:gaussexample} on the C: drive (so its path is C:\gaussexample),
download {bf:msbur.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/msbur.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\msbur.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:y = trimr(y,1,0) - trimr(lagn(y,1),1,0);}{p_end}
{p 8 8 2}{cmd:{c -(}pt,mpt,adf,za,mza,msb,mzt,tb,cbar{c )-} = sbur_multiple_gls(y, 3|0|48, 0, 4, 0, 0);}{p_end}
{p 8 8 2}{cmd:pt~mpt~adf~za;}{p_end}
{p 8 8 2}{cmd:mza~msb~mzt~cbar;}{p_end}
{p 8 8 2}{cmd:tb';}{p_end}

{dlgtab:Part 2: the pretest - Perron and Yabu (2009)}

{pstd}
The GAUSS code used in this part is {bf:qfgls.prg}, the original program
written by the authors of the pretest (Perron and Yabu 2009) and made
available on the internet by them; {bf:pycode.src} wraps its main body
verbatim in a callable procedure so that the examples below run with a
single paste.

{pstd}{bf:Example 15}{p_end}
{pstd}The Perron-Yabu (2009) pretest with the unit root tests (the pretest
values are the first panel of the output; the level-and-slope form since model(break) is
the default):{p_end}
{phang2}{cmd:. ckptest y, breaks(2) maxiter(20)}{p_end}
{p 8 8 2}expected: pyexpw=1.870025902327  TB=50 (1984m2); no rejection at the 10% level (cv 2.48){p_end}

{pstd}
To reproduce the same numbers in the original Perron-Yabu GAUSS code,
create a folder named {bf:gaussexample} on the C: drive (so its path is
C:\gaussexample), download {bf:pycode.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/pycode.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\pycode.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}expw, tb{c )-} = pyexpw(y, 3, 2, 0.15);}{p_end}
{p 8 8 2}{cmd:expw~tb;}{p_end}

{pstd}{bf:Example 16}{p_end}
{pstd}The pretest under model(slope) (the slope-only form):{p_end}
{phang2}{cmd:. ckptest y, model(slope) maxiter(20)}{p_end}
{p 8 8 2}expected: pyexpw=-0.259065787183  TB=78 (1986m6){p_end}

{pstd}
To reproduce the same numbers in the original Perron-Yabu GAUSS code,
create a folder named {bf:gaussexample} on the C: drive (so its path is
C:\gaussexample), download {bf:pycode.src} into that folder from
{browse "https://www.eruygurakademi.com/datasets/ckptest/pycode.src"}, then
paste the following GAUSS program into GAUSS and run it (Run / F5); the
data are loaded directly from the URL:{p_end}

{p 8 8 2}{cmd:new;}{p_end}
{p 8 8 2}{cmd:#include c:\gaussexample\pycode.src;}{p_end}
{p 8 8 2}{cmd:format /rd 20,12;}{p_end}
{p 8 8 2}{cmd:y = loadd("https://www.eruygurakademi.com/datasets/narayanp/narayanp.dta", "y");}{p_end}
{p 8 8 2}{cmd:{c -(}expw, tb{c )-} = pyexpw(y, 2, 2, 0.15);}{p_end}
{p 8 8 2}{cmd:expw~tb;}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ckptest} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(pt)}}feasible point optimal PT statistic{p_end}
{synopt:{cmd:r(mpt)}}modified feasible point optimal MPT statistic{p_end}
{synopt:{cmd:r(adf)}}ADF-GLS t statistic{p_end}
{synopt:{cmd:r(za)}}ZA statistic{p_end}
{synopt:{cmd:r(mza)}}MZA statistic{p_end}
{synopt:{cmd:r(msb)}}MSB statistic{p_end}
{synopt:{cmd:r(mzt)}}MZT statistic{p_end}
{synopt:{cmd:r(cbar)}}noncentrality parameter c-bar{p_end}
{synopt:{cmd:r(lags)}}selected lag order of the spectral AR regression{p_end}
{synopt:{cmd:r(nbreaks)}}number of breaks{p_end}
{synopt:{cmd:r(bgminp)}}minimum Breusch-Godfrey p-value at the selected lag{p_end}
{synopt:{cmd:r(bglags)}}highest Breusch-Godfrey order tested (after automatic resolution and cap){p_end}
{synopt:{cmd:r(bgdf)}}degrees-of-freedom floor for the Breusch-Godfrey auxiliary regressions{p_end}
{synopt:{cmd:r(T)}}number of observations{p_end}

{p2col 5 18 22 2: Scalars (pretest; not saved with {opt nopretest})}{p_end}
{synopt:{cmd:r(pyexpw)}}Perron-Yabu Exp-W(FS) statistic{p_end}
{synopt:{cmd:r(pybreakpos)}}pretest break date, observation number{p_end}
{synopt:{cmd:r(pybreakdate)}}pretest break date, time variable units{p_end}
{synopt:{cmd:r(pycv10)}, {cmd:r(pycv5)}, {cmd:r(pycv1)}}pretest critical
values at the 10, 5 and 1 percent levels{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:ckptest}{p_end}
{synopt:{cmd:r(varname)}}name of the tested variable{p_end}
{synopt:{cmd:r(model)}}model code (0, 1, 2 or 3){p_end}
{synopt:{cmd:r(method)}}{cmd:dp} or {cmd:brute}{p_end}
{synopt:{cmd:r(penalty)}}{cmd:maic} or {cmd:bic}{p_end}
{synopt:{cmd:r(breakdates)}}break dates in time variable units{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(cv)}}4x4 matrix of critical values; rows MSB, MZA, MZT, PT
(PT row applies to both PT and MPT; MZT row applies to both ADF and MZT; MZA
row applies to both ZA and MZA); columns 1, 2.5, 5 and 10 percent{p_end}
{synopt:{cmd:r(breakpos)}}break positions within the estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Bai, J. and P. Perron. 2003. Computation and analysis of multiple structural
change models. {it:Journal of Applied Econometrics} 18: 1-22.

{phang}
Carrion-i-Silvestre, J. L., D. Kim, and P. Perron. 2009. GLS-based unit root
tests with multiple structural breaks under both the null and the alternative
hypotheses. {it:Econometric Theory} 25: 1754-1792.

{phang}
Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996. Efficient tests for an
autoregressive unit root. {it:Econometrica} 64: 813-836.

{phang}
Kejriwal, M. and P. Perron. 2010. A sequential procedure to determine the
number of breaks in trend with an integrated or stationary noise component.
{it:Journal of Time Series Analysis} 31: 305-328.

{phang}
Ng, S. and P. Perron. 2001. Lag length selection and the construction of unit
root tests with good size and power. {it:Econometrica} 69: 1519-1554.

{phang}
Perron, P. 1989. The Great Crash, the oil price shock and the unit root
hypothesis. {it:Econometrica} 57: 1361-1401.

{phang}
Perron, P. and S. Ng. 1996. Useful modifications to some unit root tests
with dependent errors and their local asymptotic properties.
{it:Review of Economic Studies} 63: 435-463.

{phang}
Perron, P. and Z. Qu. 2006. Estimating restricted structural change models.
{it:Journal of Econometrics} 134: 373-399.

{phang}
Perron, P. and Z. Qu. 2007. A simple modification to improve the finite
sample properties of Ng and Perron's unit root tests.
{it:Economics Letters} 94: 12-19.

{phang}
Perron, P. and T. Yabu. 2009. Testing for shifts in trend with an
integrated or stationary noise component. {it:Journal of Business and}
{it:Economic Statistics} 27: 369-396.

{phang}
Stock, J. H. 1999. A class of tests for integration and cointegration. In
{it:Cointegration, Causality, and Forecasting: A Festschrift for Clive W. J.}
{it:Granger}, 135-167. Oxford University Press.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye.{break}
{browse "https://www.eruygurakademi.com"}{break}
eruygurakademi@gmail.com

{pstd}
{bf:ckptest} v1.0.0 -- July 2026

{pstd}
{bf:ckptest} is a Stata/Mata port of {bf:msbur.src}, the original GAUSS
code of Carrion-i-Silvestre, Kim, and Perron (2009), distributed by
Josep Lluis Carrion-i-Silvestre on his
{browse "https://sites.google.com/view/carrion-i-silvestre/code-and-data":code and data page}.
The pretest is a Stata/Mata port of {bf:qfgls.prg}, the original GAUSS
code of Perron and Yabu (2009), distributed by Tomoyoshi Yabu on his
{browse "https://www.fbc.keio.ac.jp/~tyabu/":webpage}.


{title:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:ckptest}: CKP unit root tests up to 5 unknown
break points (Carrion-i-Silvestre, Kim, and Perron, 2009). Stata package
version 1.0.0. Available from: {browse "https://www.eruygurakademi.com"}.
