{smcl}
{* *! version 1.0.34  05aug2026}{...}
{viewerjumpto "Syntax" "grangerspec##syntax"}{...}
{viewerjumpto "Description" "grangerspec##description"}{...}
{viewerjumpto "Options" "grangerspec##options"}{...}
{viewerjumpto "Examples" "grangerspec##examples"}{...}
{viewerjumpto "Stored results" "grangerspec##results"}{...}
{viewerjumpto "Remarks" "grangerspec##remarks"}{...}
{viewerjumpto "References" "grangerspec##references"}{...}
{viewerjumpto "Author" "grangerspec##author"}{...}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:grangerspec} {hline 2}}Granger causality tests across
frequencies: Granger-causality spectra (Farne & Montanari, Computational
Economics, 2022){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:grangerspec} {it:xvar} {it:yvar} [{it:zvar}] {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt ic(string)}}information criterion for lag selection: {cmd:sc}
(default), {cmd:aic}, {cmd:hq}, or {cmd:fpe}{p_end}
{synopt :{opt max:lag(#)}}maximum lag for selection; default is
min(4, n-1){p_end}
{synopt :{opt p(#)}}fixed VAR order for the unconditional case (skips
selection){p_end}
{synopt :{opt p1(#)}}fixed order of the VAR on (x,z) in the conditional
case{p_end}
{synopt :{opt p2(#)}}fixed order of the VAR on (x,y,z) in the conditional
case{p_end}
{synopt :{opt typ:e(string)}}deterministic terms in fixed-order fits:
{cmd:none} (default), {cmd:const}, or {cmd:trend}{p_end}
{synopt :{opt notab:le}}suppress the frequency-by-frequency table{p_end}

{syntab:Bootstrap inference}
{synopt :{opt boot}}perform the stationary-bootstrap test of Farne and
Montanari (2022){p_end}
{synopt :{opt nb:oots(#)}}number of bootstrap replicates; default is
1000{p_end}
{synopt :{opt conf(#)}}confidence level; default is 0.95{p_end}
{synopt :{opt seed(#)}}random-number seed for the internally generated
bootstrap series{p_end}
{synopt :{opt boot:data(filename)}}Stata dataset with pre-generated bootstrap
series (see below){p_end}
{synopt :{opt diff}}with three variables, test the difference between the
unconditional and the conditional spectrum{p_end}
{synopt :{opt bonf:adjust}}use the intended Bonferroni levels in the max band
of the difference test (see Remarks){p_end}

{syntab:Parametric test}
{synopt :{opt bc}}Breitung-Candelon (2006) F test at each frequency{p_end}
{synoptline}
{p 4 6 2}
With two variables {cmd:grangerspec} works on the unconditional spectra in
both directions; with three variables it works on the conditional spectrum of
{it:y} to {it:x} given {it:z}. The data must be {helpb tsset} as a single time
series without gaps.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:grangerspec} provides seven tools for Granger causality in the
frequency domain, selected by the number of variables and the options:

{phang2}1. Unconditional Granger-causality spectrum in both directions
(Geweke 1982): {cmd:grangerspec x y}

{phang2}2. Conditional Granger-causality spectrum given a third variable
(Geweke 1984): {cmd:grangerspec x y z}

{phang2}3. Bootstrap test on the unconditional spectra, both directions
(Farne and Montanari 2022): {cmd:grangerspec x y, boot}

{phang2}4. Bootstrap test on the conditional spectrum:
{cmd:grangerspec x y z, boot}

{phang2}5. Bootstrap test on the difference between the unconditional and
the conditional spectrum: {cmd:grangerspec x y z, boot diff}

{phang2}6. Breitung-Candelon (2006) parametric F test, unconditional:
{cmd:grangerspec x y, bc}

{phang2}7. Breitung-Candelon test conditional on a third variable:
{cmd:grangerspec x y z, bc}

{pstd}
{ul:Requirement: stationary series.} All series must be stationary, I(0):
the spectra and every test are built on stationary-VAR representations,
and a stable VAR (every companion root modulus below one) is assumed.
Difference or detrend integrated series first - the article's own
application passes all six series through the Hodrick-Prescott filter
before testing - and check the Stability line of the output.

{pstd}
{ul:The problem it solves.} Time-domain Granger causality only says whether
the past of a series {it:y} helps predict a series {it:x} overall. The
frequency-domain Granger-causality spectrum of Geweke (1982, 1984) instead
measures the strength of the causal link at each frequency, so that
causality at low (business-cycle) and high frequencies can be
distinguished. Inference on these
spectra, however, is an open problem: the limiting distribution of the
estimated spectrum under the null of no causality is unknown (Farne and
Montanari 2022, Section 2.2). Farne and Montanari propose a bootstrap
solution: they test each frequency-specific causality against the
distribution of the median causality across frequencies computed on
stationary-bootstrap series that are independent by construction, so that the
null hypothesis is stochastic independence between the series.
{cmd:grangerspec} computes the spectra and performs this bootstrap test.

{pstd}
{ul:What the command does, step by step (unconditional case).}

{phang2}
1. It fits a VAR(p) to (x,y) by OLS, equation (1) of Farne and Montanari
(2022). The order p is selected by the chosen information criterion over
1..maxlag, or fixed by {opt p(#)}.

{phang2}
2. It computes the transfer function P(omega) of equation (2), inverting
I - sum of A(k) exp(-i 2 pi k f) at each Fourier frequency. The
frequencies are f(i) = i/N for i = 1..floor(N/2), where N is the smallest
highly composite (2,3,5) integer not below n; for the Euro Area data with
n = 76 this gives N = 80 and the 40 frequencies i/80 reported in Section 3.1
of the article.

{phang2}
3. It normalizes the system with the transform matrix S built from the
residual covariance (Section 2.1 of the article), yielding the normalized
transfer function used in the causality measure.

{phang2}
4. It evaluates the unconditional Granger-causality spectrum h[Y->X](omega)
of equation (3), the log-ratio of the spectrum of x to its intrinsic part, at
every Fourier frequency, in both directions.

{pstd}
{ul:Conditional case.} With a third variable z, the command fits a VAR on
(x,z) and a VAR on (x,y,z), builds the matrices C(omega) and Q(omega) of
Section 2.1 and evaluates the conditional spectrum h[Y->X|Z](omega) of
equation (4), which measures the direct effect of the past of y on x once the
effect mediated by the past of z is excluded.

{pstd}
{ul:Bootstrap test (option {cmd:boot}), following Section 2.3 of the article.}

{phang2}
1. It simulates B stationary-bootstrap series (Politis and Romano 1994)
applying the bootstrap independently to each observed series, with mean
block length 3.15 times the cube root of n; independence across series makes the resampled system satisfy
the null of stochastic independence.

{phang2}
2. On each bootstrap replicate it estimates the VAR (order by the information
criterion, or the fixed-order path described in the Remarks) and computes the
causality spectrum at all Fourier frequencies.

{phang2}
3. It takes the median causality across frequencies of each replicate;
replicates whose estimated VAR is non-stationary (a companion root with
modulus at or above one) are excluded.

{phang2}
4. The threshold is the 100(1-alpha) percentile (R quantile type 7) of these
medians; each observed causality above the threshold is flagged as
significant at level alpha at that frequency.

{phang2}
5. For the overall test across all frequencies it applies the conservative
Bonferroni correction of Section 2.3, using the 1-(1-conf)/F percentile with
F the number of Fourier frequencies, so that the overall level does not
exceed alpha under the null.

{pstd}
The test is consistent as the cube root of T diverges (Theorems 1 and 2 and
Appendix B of the article).

{pstd}
{ul:bootdata() format.} The dataset named in {opt bootdata()} must contain,
for the unconditional case, 2B numeric variables (the B bootstrap replicates
of x followed by the B replicates of y) and, for the conditional case, 3B
variables (x-block, y-block, z-block), with exactly n observations. This
channel makes the command fully deterministic.

{pstd}
{ul:Difference test (options {cmd:boot diff}).} With three variables the
command can also test, frequency by frequency, the signed difference between
the unconditional and the conditional spectrum, h[Y->X](omega) minus
h[Y->X|Z](omega). A significantly
positive difference indicates that part of the effect of y on x is mediated
by z; a significantly negative one indicates that conditioning on z
strengthens the measured link. The per-replicate statistic is the median of
the signed differences across frequencies; stationarity is required of all
three fitted VARs (the intersection of the three flags); the confidence band
is two-sided with quantile levels (1-conf)/2 and 1-(1-conf)/2.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt ic(string)} selects the information criterion used for VAR order
selection: {cmd:sc} (Schwarz, the default, called BIC in the article),
{cmd:aic}, {cmd:hq}, or {cmd:fpe}. The criteria are computed on a common
estimation sample that drops the first maxlag observations.

{phang}
{opt maxlag(#)} sets the maximum lag over which the criterion searches. The
default is min(4, n-1).

{phang}
{opt p(#)} fixes the VAR order in the unconditional case and skips selection.
In the fixed-order path the deterministic specification of {opt type()} is
honored.

{phang}
{opt p1(#)} and {opt p2(#)} fix the orders of the bivariate (x,z) and
trivariate (x,y,z) VARs in the conditional case. With {cmd:boot} they must be
both zero or both positive; only these two cases are supported.

{phang}
{opt type(string)} chooses the deterministic terms {cmd:none} (default),
{cmd:const}, or {cmd:trend} for fixed-order fits. When the order is selected
by the information criterion the fit always includes a constant (see
Remarks).

{phang}
{opt notable} suppresses the frequency-by-frequency table and prints only the
header, thresholds, and summary lines.

{dlgtab:Bootstrap inference}

{phang}
{opt boot} switches on the bootstrap test. With two variables it tests
both directions; with three variables it tests y to x given z.

{phang}
{opt nboots(#)} sets the number of bootstrap replicates B (default 1000). Ignored when {opt bootdata()} is given, in which case B is read from
the file.

{phang}
{opt conf(#)} sets the confidence level (default 0.95). The Bonferroni
threshold uses 1-(1-conf)/F with F the number of Fourier frequencies.

{phang}
{opt seed(#)} sets the random-number seed before the internal generation of
the stationary-bootstrap series, making a run reproducible within Stata. Use
{opt bootdata()} to reproduce bootstrap series generated elsewhere.

{phang}
{opt bootdata(filename)} supplies pre-generated bootstrap series in the
format described above, bypassing the internal generator. The file is
loaded as a Stata dataset, so its number of columns must fit within the
variable limit of your Stata edition (2,048 in Stata/BE).

{phang}
{opt diff} runs the difference test instead of the conditional test when
three variables and {cmd:boot} are given. The unconditional leg follows the
p() call chain of the unconditional inference (an IC selection overwrites a
supplied p, see Remarks); the conditional leg follows the p1()/p2() rules of
the conditional inference.

{phang}
{opt bonfadjust} replaces the max-band quantile levels of the difference
test by the intended Bonferroni ones, alpha_b/2 and 1-alpha_b/2 with
alpha_b = (1-conf)/F. It is off by default; see the Remarks for the reason it exists.

{phang}
{opt bc} computes the parametric Breitung-Candelon (2006) F test instead of
the spectra: with two variables the test is unconditional, with three
variables the third variable enters the fitted VAR. It
cannot be combined with {cmd:boot}; {opt conf()} sets the significance
threshold and a single order applies, so use {opt p()} rather than
p1()/p2(). A user-supplied p(1) is silently promoted to 2.


{marker examples}{...}
{title:Examples}

{pstd}
All examples use the Euro Area dataset of the article (76 quarters,
1999q1-2017q4), with short
variable names gdp, m3, m1, hicp, unemp, and ltrate. As Section 3.1 of
Farne and Montanari (2022) explains, the raw series (GDP, M3, and M1 in
logs; the HICP, unemployment, and long-term interest rates) are
non-stationary, so the authors, following Friedman and Schwartz (1975),
pass all six series through the Hodrick-Prescott filter (lambda = 1600)
and use the detrended cyclical components in the analysis; Figures 12-13
of the article show each series with its HP trend and the extracted
cycle. The dataset contains these cycle series.

{pstd}
{ul:1. Start here: test a pair of series.} Estimates the unconditional
spectra in both directions and tests them right away with a quick
bootstrap (300 replicates, fixed seed). Read the table for where the
causality sits and the Decision block for the verdicts; example 9 runs
the same test at reporting settings.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot nboots(300) seed(1)}{p_end}

{pstd}
{ul:2. Test with a third variable controlled.} The conditional
counterpart: tests whether y still causes x once the channel through the
past of z (here inflation) is removed. If the conditional spectrum sits
well above the unconditional one at some frequencies, z was masking the
direct link; example 15 tests that gap itself.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot nboots(300) seed(1)}{p_end}

{pstd}
{ul:3. Option ic() (when: robustness of the lag choice).} Keep the
default {cmd:sc} for most applications: it selects short lags and avoids
overfitting short samples. Rerun the test under {cmd:aic} as a robustness
check when longer dynamics are suspected; if the two orders differ,
compare the decisions before trusting either.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot ic(aic) nboots(300) seed(1)}{p_end}

{pstd}
{ul:4. Option maxlag() (when: dynamics longer than a year).} The default
4 covers one year of quarterly data; raise it, for example to 8, when the
series are strongly persistent or the frequency is monthly. Avoid values
far larger than needed, because selection drops the first maxlag
observations and precision falls in short samples.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot maxlag(8) nboots(300) seed(1)}{p_end}

{pstd}
{ul:5. Option p() (when: the order is known).} Impose the order instead
of selecting it, for example to match another study's VAR(3), here on
the parametric test, where the imposed order is used as given; {cmd:r(p)}
returns it.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, bc p(3)}{p_end}

{pstd}
{ul:6. Option type() (when: deterministic terms are needed).} With a
fixed order, {cmd:const} adds an intercept (use it when the series have
nonzero means) and {cmd:trend} a linear trend; the default {cmd:none}
suits demeaned or filtered series like these HP cycles.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, bc p(3) type(const)}{p_end}

{pstd}
{ul:7. Options p1(), p2() (when: fixed orders in the conditional test).}
Fix the orders of the (x,z) and (x,y,z) VARs when they must match a
given specification; the default (both zero) selects both by the
criterion. They must be both zero or both positive.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot p1(2) p2(2) nboots(300) seed(1)}{p_end}

{pstd}
{ul:8. Option notable (when: batch runs).} Prints the hypothesis, the
critical values, the decisions, and the conclusions without the 40-row
table; use it in loops over many pairs or when the spectra are consumed
from {cmd:r()}.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot notable nboots(300) seed(1)}{p_end}

{pstd}
{ul:9. The bootstrap test (when: reported results).} The same test at
the default B = 1000, the setting to use for the results you report. The
table marks each frequency, and the Decision block gives the
frequency-wise and the overall (Bonferroni) verdicts with the
significant ranges in cycles.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot seed(1)}{p_end}

{pstd}
{ul:10. Option nboots() (when: exploration versus final results).} Use
200-500 replicates while exploring (seconds, and the thresholds are
already close); return to 1000 or more for the results you report,
because the Bonferroni quantile sits far in the tail and needs many
replicates to be stable.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot nboots(500)}{p_end}

{pstd}
{ul:11. Option conf() (when: changing the level).} 0.95 is the standard
choice. Use 0.90 as a more liberal screen when the sample is short and
power is limited; use 0.99 when only strong rejections should count. The
Bonferroni threshold adjusts automatically.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot conf(0.90) seed(1)}{p_end}

{pstd}
{ul:12. Option seed() (when: reproducibility).} Always set a seed in
work you may need to reproduce: the same seed gives the same replicates
and decisions on the next run. Rerun with a different seed to check that
borderline conclusions do not hinge on one bootstrap draw.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot seed(12345)}{p_end}

{pstd}
{ul:13. Option bootdata() (when: fully deterministic runs).} Feed
pre-generated bootstrap series, for example in a replication archive:
any Stata dataset holding the x-replicates then the y-replicates as
columns (three blocks with three variables) can be supplied, and the
test becomes fully deterministic. The example uses the hosted file of
the Replication with R section (1,000 columns for B = 500), so its
output can be reproduced in R with the code given there.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot bootdata(https://eruygurakademi.com/datasets/grangerspec/bp500.dta)}{p_end}

{pstd}
{ul:14. Conditional bootstrap test (when: reported results).} The
counterpart of example 2 at reporting settings. On these data all 40
frequencies reject frequency-wise and the lowest ones survive the
Bonferroni correction, so the conclusion reports causality concentrated
at the longest cycles.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot nboots(500) seed(99)}{p_end}

{pstd}
{ul:15. Difference test (when: the two spectra disagree).} Run it after
examples 9 and 14 when the unconditional and conditional spectra look
different: it tells at which frequencies the gap itself is significant.
A significant negative difference (as here at low frequencies) means
conditioning on z strengthens the measured link; a positive one means
part of the effect of y on x is mediated by z.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot diff nboots(500) seed(99)}{p_end}

{pstd}
{ul:16. Option bonfadjust (when: an overall verdict is needed).}
Add it whenever the difference test should deliver an all-frequencies
decision: the default max band is uninformative (see Remarks) and flags
nearly everything, while the adjusted band is a genuine Bonferroni
correction, wider than the confidence band.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot diff bonfadjust nboots(500) seed(99)}{p_end}

{pstd}
{ul:17. Parametric BC test (when: a quick check next to the bootstrap).}
Instant and assumption-based: it takes the fitted VAR as correct, and
with p = 2 its statistic is constant across interior frequencies, so it
cannot localize causality under short lags. Use it as a complement;
prefer {cmd:boot} for the substantive analysis.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, bc}{p_end}

{pstd}
{ul:18. Conditional BC test.} The three-variable parametric variant, same
usage as example 17.

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, bc}{p_end}


{marker replication}{...}
{title:Replication with R}

{pstd}
The three pairs below produce identical output in Stata and in the R
package grangers 0.1.1, to at least 12 decimal places: the two bootstrap
pairs feed both programs the same hosted replicate files (B = 500), and
the BC test is deterministic. Bootstrap runs outside this scheme use each
program's own random draws, so their thresholds differ across programs
while the decisions are comparable.

{pstd}
{ul:R1. Unconditional bootstrap test on shared replicates.}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, boot bootdata(https://eruygurakademi.com/datasets/grangerspec/bp500.dta)}{p_end}
{pstd}R Code:{p_end}
{phang2}{cmd:library(grangers)}{p_end}
{phang2}{cmd:x <- euro_area_indicators[,1]; y <- euro_area_indicators[,2]}{p_end}
{phang2}{cmd:bpm <- as.matrix(read.csv("https://eruygurakademi.com/datasets/grangerspec/bp500.csv", header=FALSE))}{p_end}
{phang2}{cmd:bp <- array(bpm, dim=c(76, 500, 2))}{p_end}
{phang2}{cmd:Granger.inference.unconditional(x, y, nboots=500, bp=bp)}{p_end}
{phang2}{cmd:Granger.unconditional(x, y)   # the spectrum values shown in the Stata table}{p_end}

{pstd}
{ul:R2. Conditional bootstrap test on shared replicates.}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3 hicp, boot bootdata(https://eruygurakademi.com/datasets/grangerspec/bpc500.dta)}{p_end}
{pstd}R Code:{p_end}
{phang2}{cmd:library(grangers)}{p_end}
{phang2}{cmd:x <- euro_area_indicators[,1]; y <- euro_area_indicators[,2]; z <- euro_area_indicators[,4]}{p_end}
{phang2}{cmd:bpm <- as.matrix(read.csv("https://eruygurakademi.com/datasets/grangerspec/bpc500.csv", header=FALSE))}{p_end}
{phang2}{cmd:bp <- array(bpm, dim=c(76, 500, 3))}{p_end}
{phang2}{cmd:Granger.inference.conditional(x, y, z, nboots=500, bp=bp)}{p_end}
{phang2}{cmd:Granger.conditional(x, y, z)   # the spectrum values shown in the Stata table}{p_end}

{pstd}
{ul:R3. Breitung-Candelon test (deterministic).}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/grangerspec/euindicators.dta, clear}{p_end}
{phang2}{cmd:. grangerspec gdp m3, bc}{p_end}
{pstd}R Code:{p_end}
{phang2}{cmd:library(grangers)}{p_end}
{phang2}{cmd:x <- euro_area_indicators[,1]; y <- euro_area_indicators[,2]}{p_end}
{phang2}{cmd:bu <- bc_test_uncond(x, y); bu}{p_end}
{phang2}{cmd:c(pf(bu[["F-test"]][1:39], 2, bu$n-2*bu$delays, lower.tail=FALSE), pf(bu[["F-test"]][40], 1, bu$n-bu$delays, lower.tail=FALSE))   # the p-value column of the Stata table}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}Spectrum estimation (no {cmd:boot}) stores in {cmd:r()}:{p_end}
{synoptset 32 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:r(n)}}sample length{p_end}
{synopt:{cmd:r(npad)}}padded FFT length N{p_end}
{synopt:{cmd:r(nfreq)}}number of Fourier frequencies{p_end}
{synopt:{cmd:r(p)}}VAR order (unconditional){p_end}
{synopt:{cmd:r(p1)}, {cmd:r(p2)}}VAR orders (conditional){p_end}
{syntab:Matrices}
{synopt:{cmd:r(freq)}}Fourier frequencies{p_end}
{synopt:{cmd:r(gc_yx)}, {cmd:r(gc_xy)}}unconditional spectra{p_end}
{synopt:{cmd:r(gc_yxz)}}conditional spectrum{p_end}
{synopt:{cmd:r(sigma)}}residual covariance (unconditional){p_end}
{synopt:{cmd:r(sigma1)}, {cmd:r(sigma2)}}residual covariances (conditional){p_end}
{synopt:{cmd:r(roots)}}moduli of the companion roots{p_end}
{synopt:{cmd:r(roots1)}, {cmd:r(roots2)}}root moduli of the two VARs (conditional){p_end}

{pstd}With {cmd:boot} (unconditional) the command additionally stores:{p_end}
{synoptset 32 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:r(nboots)}, {cmd:r(conf)}}replicates used and confidence level{p_end}
{synopt:{cmd:r(stat_yes)}}1 if at least one stationary replicate, else 0{p_end}
{synopt:{cmd:r(nonstat_rate)}}share of non-stationary replicates{p_end}
{synopt:{cmd:r(delay_mean)}}mean bootstrap VAR order (stationary replicates){p_end}
{synopt:{cmd:r(q_x)}, {cmd:r(q_y)}}frequency-wise critical values{p_end}
{synopt:{cmd:r(q_max_x)}, {cmd:r(q_max_y)}}Bonferroni critical values{p_end}
{synopt:{cmd:r(nsig_yx)}, {cmd:r(nsig_xy)}}counts of significant frequencies{p_end}
{synopt:{cmd:r(nsig_max_yx)}, {cmd:r(nsig_max_xy)}}counts under Bonferroni{p_end}
{syntab:Matrices}
{synopt:{cmd:r(freq_sig_yx)}, {cmd:r(freq_sig_xy)}}significant frequencies{p_end}
{synopt:{cmd:r(freq_sig_max_yx)}}significant frequencies (Bonferroni, y to x){p_end}
{synopt:{cmd:r(freq_sig_max_xy)}}significant frequencies (Bonferroni, x to y){p_end}

{pstd}With {cmd:bc} the command stores {cmd:r(p)}, {cmd:r(conf)},
{cmd:r(nsig)}, and the matrices {cmd:r(freq)}, {cmd:r(F)}, {cmd:r(pval)},
{cmd:r(Fthr)}, {cmd:r(roots)}, and {cmd:r(freq_sig)} (when nonempty);
{cmd:r(mode)} is {cmd:bc_uncond} or {cmd:bc_cond}.{p_end}

{pstd}With {cmd:boot diff} the command stores {cmd:r(q_diff_sup)},
{cmd:r(q_diff_inf)}, {cmd:r(q_diff_max_sup)}, {cmd:r(q_diff_max_inf)},
{cmd:r(nonstat_rate)}, {cmd:r(nonstat_rate1)}, {cmd:r(nonstat_rate2)},
{cmd:r(p_orig)}, {cmd:r(p_orig1)}, {cmd:r(p_orig2)}, the counts
{cmd:r(nsig_sup)}, {cmd:r(nsig_inf)}, {cmd:r(nsig_max_sup)},
{cmd:r(nsig_max_inf)}, the matrices {cmd:r(freq)}, {cmd:r(diff)},
{cmd:r(freq_sup)}, {cmd:r(freq_inf)}, {cmd:r(freq_max_sup)},
{cmd:r(freq_max_inf)}, and the macro {cmd:r(bonf)} ({cmd:asis} or
{cmd:adjusted}).{p_end}

{pstd}With {cmd:boot} (conditional) the counterparts are
{cmd:r(nonstat_rate1)}, {cmd:r(nonstat_rate2)}, {cmd:r(delay1_mean)},
{cmd:r(delay2_mean)}, {cmd:r(q_x_z)}, {cmd:r(q_max_x_z)}, {cmd:r(nsig)},
{cmd:r(nsig_max)}, {cmd:r(freq_sig)}, and {cmd:r(freq_sig_max)}.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Bootstrap of the conditional test.} Section 2.3 of the article describes
a residual bootstrap for the pair (X,W) in the conditional procedure. The
implementation instead applies the stationary bootstrap independently to
all three series.

{pstd}
{ul:Deterministic terms in IC-selected fits.} Every IC-selected VAR is
fitted with a constant regardless of {opt type()}, while fixed-order fits
honor it; the output header reports the specification actually fitted. In
the unconditional bootstrap the path for p>0 replaces the supplied order
with an IC selection and computes the bootstrap spectra at that fixed
order with no deterministic terms, and the original spectra compared
against the thresholds are always recomputed through the IC path.

{pstd}
{ul:Bonferroni band of the difference test.} The max band of the
difference test sets alpha_b = (1-conf)/F but plugs it into the level
formulas, computing its quantiles at levels (1-alpha_b)/2 and
1-(1-alpha_b)/2, which for conf = 0.95 and F = 40 are 0.499375 and
0.500625: a band a hair around the median of the bootstrap distribution,
narrower than the confidence band instead of wider. As a result the
default max marks flag nearly every frequency. The option
{opt bonfadjust} provides the intended correction (levels alpha_b/2 and
1-alpha_b/2) for substantive use.

{pstd}
{ul:Excluded replicates.} Bootstrap replicates whose estimated VAR is
non-stationary are excluded from the threshold quantiles, and the share of
such replicates is reported. If no replicate is stationary the command
returns only {cmd:r(stat_yes)} = 0.


{marker references}{...}
{title:References}

{phang}
Farne, M., and A. Montanari. 2022. A bootstrap method to test
Granger-causality in the frequency domain. {it:Computational Economics} 59:
935-966.

{phang}
Geweke, J. 1982. Measurement of linear dependence and feedback between
multiple time series. {it:Journal of the American Statistical Association}
77: 304-313.

{phang}
Geweke, J. 1984. Measures of conditional linear dependence and feedback
between time series. {it:Journal of the American Statistical Association}
79: 907-915.

{phang}
Ding, M., Y. Chen, and S. L. Bressler. 2006. Granger causality: basic theory
and application to neuroscience. In {it:Handbook of Time Series Analysis},
chap. 17.

{phang}
Politis, D. N., and J. P. Romano. 1994. The stationary bootstrap.
{it:Journal of the American Statistical Association} 89: 1303-1313.

{phang}
Breitung, J., and B. Candelon. 2006. Testing for short- and long-run
causality: a frequency-domain approach. {it:Journal of Econometrics} 132:
363-378.


{marker author}{...}
{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye{break}
{browse "https://www.eruygurakademi.com":eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pstd}
{cmd:grangerspec} is a faithful Stata/Mata port of the R package
{bf:grangers} version 0.1.1 by Matteo Farne and Angela Montanari (University
of Bologna), implementing Farne and Montanari (2022). All computations
replicate the original R code and have been validated against its output.

{pstd}
grangerspec v1.0.34 - August 2026

{pstd}
{ul:Please cite as:}

{pmore}
Eruygur, H. O. 2026. {bf:grangerspec}: Granger causality tests across
frequencies: Granger-causality spectra (Farne & Montanari, Computational
Economics, 2022). Stata package version 1.0.34. Available from:
eruygurakademi.com
