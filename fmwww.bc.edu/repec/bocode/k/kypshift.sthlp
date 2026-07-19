{smcl}
{* *! version 1.3.23 17jul2026}{...}
{hline}
help for {hi:kypshift}
{hline}

{title:Title}

{p 4 8 2}
{bf:kypshift} - Testing shifts between I(1) and I(0) regimes at unknown dates
(Kejriwal-Yu-Perron 2020)

{title:Syntax}

{p 8 16 2}
{cmd:kypshift} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt maxb:reaks(#)}}maximum number of persistence breaks, between 2 and 5;
default is {cmd:maxbreaks(5)}{p_end}
{synopt:{opt trim(#)}}trimming fraction for the minimum regime length; default is
{cmd:trim(0.15)}{p_end}
{synopt:{opt eta(#)}}significance level of the sequential procedure; default is
{cmd:eta(0.10)}{p_end}
{synopt:{opt bic:maxlag(#)}}maximum lag order considered by the BIC; default is
{cmd:bicmaxlag(8)}{p_end}
{synopt:{opt rep:s(#)}}number of wild bootstrap replications; default is
{cmd:reps(400)}{p_end}
{synopt:{opt seed(#)}}set the Stata random-number seed before drawing the bootstrap
weights{p_end}
{synopt:{opt pmseed(#)}}use the deterministic Park-Miller replication stream with the
given seed instead of Stata draws; see {it:Validation} below{p_end}
{synopt:{opt nodots}}suppress the progress dots{p_end}
{synopt:{opt asympcv}}also report the Kejriwal-Perron-Zhou (2013) and Bai-Perron
(1998, 2003) asymptotic critical values with the KPZ hybrid decision; requires
{cmd:trim(0.15)}{p_end}
{synoptline}
{p 4 6 2}
The variable must contain the series of interest itself (for example an inflation
rate); {cmd:kypshift} does not transform the data. The data must be {cmd:tsset}
without gaps in the estimation sample.

{title:Description}

{p 4 4 2}
{cmd:kypshift} detects multiple shifts in the persistence of a univariate time
series, that is, changes between unit root I(1) and stationary I(0) regimes in
either direction, under heteroskedasticity of unknown form.
Both the number of breaks and their dates are treated as unknown. The command
implements the bootstrap procedures of Kejriwal, Yu and Perron (2020) built on the
sup-Wald statistics of Kejriwal, Perron and Zhou (2013); the statistical background
and the division of labor between the two articles are laid out in the next
section.

{p 4 4 2}
A single run reports, in order: the full-sample stability tests (the directional
statistics sup F1a(k) and sup F1b(k), their maximum W1(k), the G statistics, and
the Wmax/UDmax hybrid decision with bootstrap p-values); optionally the KPZ
asymptotic critical values ({opt asympcv}); the sequential estimation of the number
of breaks with the selected break dates; and the diagnostics of Tables I and II of
the 2020 article (pure mean shift Wald test, largest AR coefficient sum with its
Andrews-Guggenberger band, the selected model label, the Cavaliere-Taylor ratio and
ADF tests, and the regime-wise persistence table when persistence breaks are
found). All displayed quantities are returned in {cmd:r()}.

{title:The two articles behind the command}

{p 4 4 2}
{bf:Kejriwal, Perron and Zhou (2013, Econometric Theory) - the statistics:}

{p 8 12 2}- proposes the sup-Wald tests used throughout the command: the directional
statistics sup F1a(k) (unit root in odd regimes under the alternative) and
sup F1b(k) (unit root in even regimes), their maximum W1(k) for the case of unknown
direction, and Wmax for an unknown number of breaks [KPZ]{p_end}
{p 8 12 2}- computes them from the regression of the first difference on a
constant, the lagged level and lagged differences, under the Model 1a and Model 1b
restrictions, using the restricted dynamic programming of Perron and Qu
(2006) [KPZ]{p_end}
{p 8 12 2}- proves (Theorem 3) that each directional test is inconsistent against
the other direction, so the pair identifies whether the series starts I(1) or
I(0) [KPZ]{p_end}
{p 8 12 2}- tabulates asymptotic critical values (Table 1; homoskedastic errors,
15 percent trimming) [KPZ]{p_end}
{p 8 12 2}- proposes, in its Section 4, the hybrid decision rule that gives the W
tests their interpretation: because the W tests reject with probability one in
large samples even when the process is stable I(0), the article pairs them with
the Bai-Perron structural change tests and rejects the null that the process is
stable I(1) or stable I(0) only when both tests reject at the chosen significance
level; the asymptotic size of this rule is bounded by that level and the rule is
consistent against processes that switch between I(1) and I(0) regimes. With the
number of breaks unknown, Wmax is paired with UDmax [KPZ]{p_end}
{p 8 12 2}- leaves two questions open: inference under heteroskedasticity, and the
estimation of the number of breaks [answered by KYP]{p_end}

{p 4 4 2}
{bf:Kejriwal, Yu and Perron (2020, JTSA) - the procedure:}

{p 8 12 2}- replaces the asymptotic critical values with a wild bootstrap that
stays valid under heteroskedasticity: I(1) bootstrap samples are
built by cumulating sign-flipped residuals and I(0) samples by sign-flipping
residuals directly, with Rademacher weights, and each family of statistics is
compared with its own bootstrap distribution [KYP]{p_end}
{p 8 12 2}- pairs the W statistics with the G statistics of the Bai and Perron
(1998, 2003) framework in the hybrid Wmax/UDmax decision: the stability null is
rejected only if both families reject, with joint p-value p* = max(p(Wmax),
p(UDmax)) [KYP]{p_end}
{p 8 12 2}- estimates the number of breaks sequentially: if p* exceeds
{opt eta(#)} the series is judged stable; otherwise, for each candidate number of
breaks i the dates are estimated by minimizing the sum of squared residuals, the
one-break tests are applied within each of the i+1 regimes, and the procedure
stops at the first i whose minimum regime p-value exceeds the Bonferroni-adjusted
threshold [KYP]{p_end}
{p 8 12 2}- selects the autoregressive lag order by BIC with maximum
{opt bicmaxlag(#)}, exactly as in the authors' code: a full-sample selection for
the stability tests and a dating-based selection for each candidate partition; all
bootstrap statistics use an AR(1) specification as recommended in the
article [KYP]{p_end}
{p 8 12 2}- provides the empirical diagnostics of its Tables I and II (mean shift
Wald test, regime AR sums, AG bands, CT tests) [KYP]{p_end}

{p 4 4 2}
{bf:What KPZ (2013) concretely adds to kypshift, and why it is useful:}

{p 8 12 2}- The sup F1a(k) and sup F1b(k) columns of the full-sample table and the
matrices {cmd:r(f1a)}, {cmd:r(f1b)}. Always reported, no option needed. Advantage:
the direction of the persistence change is read from the tests themselves, before
any break date is estimated; the KYP output collapses the two into their maximum
and loses this information at the test level.{p_end}
{p 8 12 2}- The {opt asympcv} option, which displays the KPZ Table 1 critical
values (10, 5, 2.5 and 1 percent) next to sup F1a(k), sup F1b(k), W1(k) and Wmax
and returns them in {cmd:r(cvf1a)}, {cmd:r(cvf1b)}, {cmd:r(cvw1)}, {cmd:r(cvwmax)}.
Two advantages: it is the only formal inference available for the directional
components, since the KYP bootstrap does not produce p-values for them; and it
gives a fast bootstrap-free assessment when the errors are plausibly homoskedastic.
It requires {cmd:trim(0.15)} and should be read with the homoskedasticity caveat
printed below the table; under heteroskedasticity the bootstrap p-values remain
the primary evidence.{p_end}

{p 8 12 2}- The asymptotic hybrid decision printed at the bottom of the
{opt asympcv} table: Wmax and UDmax are compared with the KPZ and the Bai-Perron
(1998, 2003) critical values and the reported decision is the smallest tabulated
level at which both reject. This is the Section 4 rule of KPZ (2013) in its
original asymptotic form; table [1] of the output applies the same rule with wild
bootstrap p-values through p* = max(p(Wmax), p(UDmax)), which is the KYP (2020)
operationalization of the same idea.{p_end}

{p 4 4 2}
Everything else in the command implements KYP (2020).

{title:Choosing the options}

{p 4 4 2}
The defaults replicate the empirical configuration of the article (Section 8), which
uses {cmd:maxbreaks(5)}, {cmd:trim(0.15)}, {cmd:eta(0.10)}, {cmd:bicmaxlag(8)} and 400
bootstrap replications on monthly inflation series with T = 581. Larger {opt reps(#)}
values sharpen the bootstrap p-values at a proportional cost in time. The trimming
fraction fixes the minimum admissible regime length at round({it:trim} x T) effective
observations; lowering it admits shorter regimes but weakens the within-regime tests.

{p 4 4 2}
Runtime grows roughly with the square of the sample size and linearly in
{opt reps(#)}. As a reference point, a series with T = 581 and {cmd:reps(400)} takes
about five minutes. Progress dots are displayed by default, one per bootstrap
replication.

{p 4 4 2}
If a candidate partition produces a regime whose minimum segment length
round({it:trim} x T_regime) falls below the number of regressors (2 plus the selected
lag order), the dynamic programming initializations rely on nearly singular designs.
The original MATLAB code proceeds through such inversions and MATLAB prints its own
console warning; {cmd:kypshift} does the same and prints an equivalent warning once
per run. In that situation consider reducing {opt bicmaxlag(#)}. The same caution
applies to the bootstrap ADF tests of the regime table when a regime is very short
(roughly below 45 observations): their internal lag selection then operates on
nearly singular designs and the resulting p-values should not be taken at face
value. {cmd:kypshift} sorts the data by the {cmd:tsset} time variable before
estimation, so results do not depend on the current sort order of the dataset.

{title:Datasets used in the examples}

{p 4 4 2}
All example datasets are hosted at
{browse "https://www.eruygurakademi.com/datasets/kypshift/"} and can be loaded
directly with {cmd:use}. {cmd:kyp_oecd.dta} contains the empirical data of the
article: monthly CPI inflation rates (1200 times the log difference of the CPI) for
19 OECD countries, 1960m2-2008m6, T = 581, built from the data file distributed with
the authors' replication code; the time variable is {cmd:mdate}. The files
{cmd:kypsynth_a.dta} to {cmd:kypsynth_f.dta} are synthetic series with known
properties, used both below and in the validation of the package: {cmd:kypsynth_a}
has a single I(0)-to-I(1) persistence shift, {cmd:kypsynth_b} has two persistence
shifts, {cmd:kypsynth_c} is I(0) with a pure mean shift, {cmd:kypsynth_e} is stable
white noise with no break, and {cmd:kypsynth_f} is a stable autocorrelated series
whose BIC lag selection is positive. Their time variable is {cmd:t}.

{title:Examples}

{p 4 4 2}
{bf:Example 1: a first run on a series with one persistence shift.} The series
switches from a stationary AR(1) to a unit root process at observation 100. With
200 bootstrap replications the run takes a few seconds and the output shows the
full-sample stability tests, the sequential procedure and the Table I diagnostics.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_a.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(1000)}{p_end}

{p 4 4 2}
{bf:Example 2: replicating the Austria row of Table I of the article.} The
configuration below is the one used in Section 8 of the article. The defaults
already set maxbreaks(5), trim(0.15) and eta(0.10), so only the lag bound, the
replications and the seed are given. Expected output: one persistence break dated
1969m7; pure mean shifts not rejected (robust Wald 0.22 against the 10 percent
critical value 2.71, hence "Yes" in column 4); largest AR coefficient sum 0.65 with
BIC lag 11; AG 90 percent band [0.47, 0.87]; selected model "I(0) with 1 mean
shift(s)". These match Table I digit for digit because all of these quantities are
deterministic given the selected break; the runtime is about five minutes. The
bootstrap p-values, in contrast, are expected to match the article only up to
Monte Carlo error (roughly plus or minus 0.02 at 400 replications), since the
authors' own pipeline reseeds from the clock on every run and its exact draws
cannot be reproduced by anyone, including the authors.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kyp_oecd.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift austria, bicmaxlag(8) reps(400) seed(12345)}{p_end}

{p 4 4 2}
{bf:Example 3: a country with a genuine persistence break and the Table II regime}
{bf:table.} For Belgium the article reports one persistence break with regime
sequence I(0)-I(1). Because the mean shift hypothesis is rejected, {cmd:kypshift}
prints the regime-by-regime persistence table (AR sum, AG band, bootstrap ADF
p-value and BIC lag for each regime), the counterpart of Table II of the article.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kyp_oecd.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift belgium, bicmaxlag(8) reps(400) seed(12345)}{p_end}

{p 4 4 2}
{bf:Example 4: controlling the search with maxbreaks(), trim() and eta().} A
smaller {opt maxbreaks(#)} restricts the alternative space and shortens the run
roughly in proportion; a larger {opt trim(#)} forces longer regimes, which
stabilizes the within-regime tests but rules out breaks close together or close to
the sample ends; a smaller {opt eta(#)} makes the sequential procedure stop earlier
and select fewer breaks.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kyp_oecd.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift france, maxbreaks(2) bicmaxlag(8) reps(400) seed(2)}{p_end}
{p 8 12 2}{inp:. kypshift france, trim(0.20) bicmaxlag(8) reps(400) seed(2)}{p_end}
{p 8 12 2}{inp:. kypshift france, eta(0.05) bicmaxlag(8) reps(400) seed(2)}{p_end}

{p 4 4 2}
{bf:Example 5: reproducibility with seed().} Two runs with the same seed give
identical output to the last digit; without {opt seed(#)} the current state of the
Stata random-number generator is used, so results differ across runs. This is a
deliberate improvement over the authors' pipeline, which reseeds from the clock.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_a.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(42)}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(42)}{p_end}

{p 4 4 2}
{bf:Example 6: multiple breaks and deep sequential search.} On the two-shift
series the sequential procedure explores partitions with up to five breaks; the
candidate dates for every depth are stored in {cmd:r(tmpnt)} and the full p-value
matrix in {cmd:r(pvall)}. A small {opt reps(#)} is used here only to keep the demo
fast; use several hundred replications in real work.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_b.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(2) reps(100) seed(7)}{p_end}
{p 8 12 2}{inp:. matrix list r(tmpnt)}{p_end}
{p 8 12 2}{inp:. matrix list r(pvall)}{p_end}

{p 4 4 2}
{bf:Example 7: the no-break and pure mean shift cases.} On the stable series the
procedure selects zero breaks, the AG band on the full-sample AR sum determines the
I(0) or I(1) label in column 7, and the regime table is reported as not applicable.
On the mean shift series one break is found but the robust Wald test does not
reject pure mean shifts, so the model label is "I(0) with 1 mean shift(s)".

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_e.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(3)}{p_end}
{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_c.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(4)}{p_end}

{p 4 4 2}
{bf:Example 8: the deterministic replication stream pmseed().} With {opt pmseed(#)}
the wild bootstrap weights come from a Park-Miller stream that is bit-identical to
the one used by the Octave reference programs in the validation package, so the
entire run is reproducible across software. The seeds below reproduce the shipped
reference outputs for the validation series (see the {it:Validation} section).

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_a.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(10) pmseed(20260709)}{p_end}

{p 4 4 2}
{bf:Example 9: directional components and asymptotic critical values.} The
{opt asympcv} option compares sup F1a(k), sup F1b(k), W1(k) and Wmax with the KPZ
(2013) asymptotic critical values at the 10, 5, 2.5 and 1 percent levels. On the
kypsynth_a series (I(0) followed by I(1)) sup F1a rejects while sup F1b does not,
identifying the first regime as I(0) in line with KPZ Theorem 3.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kypsynth_a.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift y, bicmaxlag(5) reps(200) seed(1000) asympcv}{p_end}
{p 8 12 2}{inp:. matrix list r(f1a)}{p_end}
{p 8 12 2}{inp:. matrix list r(cvwmax)}{p_end}

{p 4 4 2}
{bf:Example 10: using the stored results.} All displayed quantities are returned in
{cmd:r()}; the break count, the dates, the Table I diagnostics and the regime table
can be picked up programmatically after the run.

{p 8 12 2}{inp:. use https://eruygurakademi.com/datasets/kypshift/kyp_oecd.dta, clear}{p_end}
{p 8 12 2}{inp:. kypshift austria, bicmaxlag(8) reps(400) seed(12345)}{p_end}
{p 8 12 2}{inp:. return list}{p_end}
{p 8 12 2}{inp:. display r(nb) " break(s), model: " r(selmodel)}{p_end}
{p 8 12 2}{inp:. display "AG band: [" %5.2f r(aglow) ", " %5.2f r(agup) "]"}{p_end}

{title:Remarks on the relation to the published article}

{p 4 4 2}
{cmd:kypshift} is a port of the authors' MATLAB program {cmd:detnumbreak.m}
distributed with the article. Where the code and the text of the article differ, the
port follows the code, since the code is what generated the published empirical
results. Three such differences were found and are documented here for transparency.

{p 4 4 2}
First, the G statistic in the code normalizes the difference in sums of squared
residuals by 2k, the number of restricted parameters with k breaks, while equation (5)
of the article shows k. The bootstrap critical values are computed with the same
formula, so p-values and all decisions are unaffected by the scaling.

{p 4 4 2}
Second, when testing the partition with i estimated breaks the code compares the
minimum regime p-value with 1-(1-eta)^(1/i), while Section 5.3 of the article states
the threshold 1-(1-eta)^(1/(l+1)) for the test of l against l+1 breaks. The port
follows the code.

{p 4 4 2}
Third, the I(1) bootstrap samples in the code initialize the pre-sample values at
zero, while step (3) of the bootstrap algorithm in the article carries over the
observed values of the series. Because the test regressions include regime intercepts,
the statistics are invariant to this level difference.

{p 4 4 2}
A further remark concerns reproducibility of the original program: its bootstrap loop
reseeds the random-number generator on every call and runs under parfor, so two runs
of the authors' pipeline generally give different p-values. {cmd:kypshift} with
{opt seed(#)} is exactly reproducible from run to run.

{title:Validation}

{p 4 4 2}
The port was validated against a deterministic Octave reference built from the
authors' MATLAB code, modified only by removing parallelism and reseeding and by
replacing the Rademacher generator with a Park-Miller stream that is bit-identical
across platforms. Feeding the same stream to both engines makes the entire pipeline
deterministic, so every intermediate and final quantity can be compared digit by
digit. Across four synthetic configurations covering every code branch (all sequential
depths, the persistence, pure mean shift and no-break cases, the CT tests and the
regime table), more than 400 logged quantities (test statistics, every bootstrap
statistic, critical values, p-values, candidate break dates, regression
coefficients, standard errors, confidence bands and the selected number of breaks)
agree between the Octave reference and {cmd:kypshift} with a worst relative
difference of 1.4e-12. The only exclusion is the bootstrap ADF p-value inside
regimes shorter than about 45 observations, where the computation is nearly
singular and engines legitimately differ; this region is flagged by the runtime
warning described above.

{p 4 4 2}
The option {opt pmseed(#)} activates the same Park-Miller stream in {cmd:kypshift}, so
these comparisons can be reproduced independently. The reference programs, the
synthetic series and the reference outputs are available at
{browse "https://eruygurakademi.com/datasets/kypshift/kypshift_octave_validation.zip"}.

{title:Stored results}

{p 4 4 2}{cmd:kypshift} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(nb)}}selected number of persistence breaks{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{synopt:{cmd:r(wmax)}}Wmax statistic{p_end}
{synopt:{cmd:r(udmax)}}UDmax statistic{p_end}
{synopt:{cmd:r(pvw)}}bootstrap p-value of Wmax{p_end}
{synopt:{cmd:r(pvbp)}}bootstrap p-value of UDmax{p_end}
{synopt:{cmd:r(pv)}}joint p-value, max of the two{p_end}
{synopt:{cmd:r(cvw)}}bootstrap critical value of Wmax at level eta{p_end}
{synopt:{cmd:r(cvbp)}}bootstrap critical value of UDmax at level eta{p_end}
{synopt:{cmd:r(hstat)}}hybrid Hmax statistic{p_end}
{synopt:{cmd:r(optlag0)}}BIC lag order selected on the full sample{p_end}
{synopt:{cmd:r(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:r(eta)}}significance level{p_end}
{synopt:{cmd:r(trim)}}trimming fraction{p_end}
{synopt:{cmd:r(maxlag)}}maximum BIC lag order{p_end}
{synopt:{cmd:r(maxbreaks)}}maximum number of breaks{p_end}

{synopt:{cmd:r(meanwald)}}robust Wald test of pure mean shifts{p_end}
{synopt:{cmd:r(meanwaldcv)}}its chi-squared 10 percent critical value{p_end}
{synopt:{cmd:r(meanshift)}}1 if pure mean shifts are not rejected, 0 otherwise{p_end}
{synopt:{cmd:r(arsum)}}largest regime-wise AR coefficient sum{p_end}
{synopt:{cmd:r(aglow)}}lower end of the AG 90 percent band{p_end}
{synopt:{cmd:r(agup)}}upper end of the AG 90 percent band{p_end}
{synopt:{cmd:r(adfp)}}CT bootstrap ADF p-value, demeaned{p_end}
{synopt:{cmd:r(adfptrend)}}CT bootstrap ADF p-value, detrended{p_end}
{synopt:{cmd:r(ctk1)}}CT ratio statistic K1{p_end}
{synopt:{cmd:r(ctk1p)}}CT ratio statistic K1-prime{p_end}
{synopt:{cmd:r(ctk4)}}CT ratio statistic K4{p_end}
{synopt:{cmd:r(ctpv1)}}bootstrap p-value of K1{p_end}
{synopt:{cmd:r(ctpv2)}}bootstrap p-value of K1-prime{p_end}
{synopt:{cmd:r(ctpv3)}}bootstrap p-value of K4{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(selmodel)}}selected model label, column 7 of Table I{p_end}
{synopt:{cmd:r(ctmodel)}}CT selection label, column 8 of Table I{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(table2)}}regime-wise AR sums, AG bands, ADF p-values and lags{p_end}
{synopt:{cmd:r(regmodel)}}regime-wise I(0)/I(1) indicators{p_end}
{synopt:{cmd:r(wstats)}}W statistics for 1 to maxbreaks breaks{p_end}
{synopt:{cmd:r(bpstats)}}G statistics for 1 to maxbreaks breaks{p_end}
{synopt:{cmd:r(f1a)}}sup F1a statistics for 1 to maxbreaks breaks{p_end}
{synopt:{cmd:r(f1b)}}sup F1b statistics for 1 to maxbreaks breaks{p_end}
{synopt:{cmd:r(cvf1a)}}KPZ asymptotic critical values for sup F1a (with asympcv){p_end}
{synopt:{cmd:r(cvf1b)}}KPZ asymptotic critical values for sup F1b (with asympcv){p_end}
{synopt:{cmd:r(cvw1)}}KPZ asymptotic critical values for W1(k) (with asympcv){p_end}
{synopt:{cmd:r(cvwmax)}}KPZ asymptotic critical values for Wmax (with asympcv){p_end}
{synopt:{cmd:r(cvg1)}}Bai-Perron critical values for G1(k) (with asympcv){p_end}
{synopt:{cmd:r(cvudmax)}}Bai-Perron critical values for UDmax (with asympcv){p_end}
{synopt:{cmd:r(pvall)}}full matrix of bootstrap p-values of the sequential
procedure{p_end}
{synopt:{cmd:r(tmpnt)}}estimated break dates (observation indices) for each candidate
number of breaks{p_end}

{title:References}

{p 4 8 2}
Bai, J., and P. Perron. 1998. Estimating and testing linear models with multiple
structural changes. {it:Econometrica} 66: 47-78.

{p 4 8 2}
Bai, J., and P. Perron. 2003. Computation and analysis of multiple structural change
models. {it:Journal of Applied Econometrics} 18: 1-22.

{p 4 8 2}
Andrews, D. W. K., and P. Guggenberger. 2014. A conditional-heteroskedasticity-robust
confidence interval for the autoregressive parameter. {it:Review of Economics and}
{it:Statistics} 96: 376-381.

{p 4 8 2}
Cavaliere, G., and A. M. R. Taylor. 2008. Testing for a change in persistence in the
presence of non-stationary volatility. {it:Journal of Econometrics} 147: 84-98.

{p 4 8 2}
Cavaliere, G., and A. M. R. Taylor. 2009. Bootstrap M unit root tests. {it:Econometric}
{it:Reviews} 28: 393-421.

{p 4 8 2}
Kejriwal, M. 2020. A robust sequential procedure for estimating the number of
structural changes in persistence. {it:Oxford Bulletin of Economics and Statistics}
82: 669-685.

{p 4 8 2}
Kejriwal, M., P. Perron, and J. Zhou. 2013. Wald tests for detecting multiple
structural changes in persistence. {it:Econometric Theory} 29: 289-323.

{p 4 8 2}
Kejriwal, M., X. Yu, and P. Perron. 2020. Bootstrap procedures for detecting multiple
persistence shifts in heteroskedastic time series. {it:Journal of Time Series}
{it:Analysis} 41: 676-690. DOI: 10.1111/jtsa.12528.

{p 4 8 2}
Liu, R. Y. 1988. Bootstrap procedures under some non-iid models. {it:Annals of}
{it:Statistics} 16: 1696-1708.

{p 4 8 2}
Perron, P., and Z. Qu. 2006. Estimating restricted structural change models.
{it:Journal of Econometrics} 134: 373-399.

{title:Author}

{p 4 4 2}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
eruygur@gmail.com

{p 4 4 2}
Eruygur Academy and Consulting{break}
{browse "https://www.eruygurakademi.com"}{break}
eruygurakademi@gmail.com

{p 4 4 2}
kypshift v1.3.23 - July 2026

{p 4 4 2}
The tests implemented here were proposed by Mohitosh Kejriwal (Krannert School of
Management, Purdue University), Xuewen Yu (Krannert School of Management, Purdue
University) and Pierre Perron (Department of Economics, Boston University). The Stata
implementation is a port of the authors' MATLAB replication code for the article.

{p 4 4 2}
Please cite as: Eruygur, H. O. 2026. kypshift: Stata module for bootstrap detection of
multiple persistence shifts in heteroskedastic time series. Statistical Software
Components, Boston College Department of Economics.
