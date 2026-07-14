{smcl}
{* *! version 1.0.0  12jul2026}{...}
{vieweralsosee "xtmixedroot methods" "help xtmixedroot_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtmixedroot##syntax"}{...}
{viewerjumpto "Description" "xtmixedroot##description"}{...}
{viewerjumpto "Options" "xtmixedroot##options"}{...}
{viewerjumpto "Interpreting the output" "xtmixedroot##interpret"}{...}
{viewerjumpto "Remarks and practical guidance" "xtmixedroot##remarks"}{...}
{viewerjumpto "Examples" "xtmixedroot##examples"}{...}
{viewerjumpto "Stored results" "xtmixedroot##results"}{...}
{viewerjumpto "References" "xtmixedroot##references"}{...}
{viewerjumpto "Author" "xtmixedroot##author"}{...}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{bf:xtmixedroot} {hline 2}}Fraction of nonstationary (unit-root) units
in a mixed panel: the Ng (2008) estimator with Westerlund (2016)
bias-adjusted fixed-T inference{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtmixedroot} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Ng (2008) estimator}
{synopt :{opt est:imator(a|b|c)}}A: heterogeneous AR(p) dynamics (default);
B: adds control for cross-sectional correlation; C: adds incidental linear
trends{p_end}
{synopt :{opt l:ags(#)}}fixed AR lag order p for every unit; default is
unit-by-unit BIC selection{p_end}
{synopt :{opt maxl:ags(#)}}maximum lag order for BIC selection; default
{cmd:maxlags(4)}{p_end}
{synopt :{opt f:actors(#)}}number of lags of the factor proxy in Estimator B;
default {cmd:factors(1)}, i.e. the proxy and its first lag{p_end}
{synopt :{opt pc}}use the first principal component of the differenced panel
as the factor proxy instead of the cross-sectional average{p_end}
{synopt :{opt hac(#)}}truncation lag M of the Bartlett (Newey-West) kernel for
the HAC standard error; default {cmd:hac(2)}{p_end}

{syntab:Hypothesis and inference}
{synopt :{opt t:heta0(#)}}null value theta_0 in (0,1]; default
{cmd:theta0(1)} (all units nonstationary){p_end}
{synopt :{opt lev:el(#)}}confidence level for the theta interval; default
{cmd:level(95)}{p_end}
{synopt :{opt dem:ean}}use cross-sectionally demeaned data when estimating the
error variance and kurtosis of the Westerlund statistics (recommended with
common time effects){p_end}

{syntab:Reporting}
{synopt :{opt class:ify}}classify individual units as I(1)/I(0) by their
estimated dominant autoregressive root (Ng 2008, Sec. 4){p_end}
{synopt :{opt list(#)}}number of units displayed by {cmd:classify}; default
{cmd:list(15)} (the full table is always stored in {cmd:r(units)}){p_end}
{synopt :{opt gr:aph}}plot the cross-sectional variance of the raw and
rescaled panel with the implied theta trend line{p_end}
{synoptline}
{p 4 6 2}The panel must be {helpb xtset}, balanced, and without gaps.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtmixedroot} estimates {it:theta}, the fraction of units in a panel
whose autoregressive representation contains a unit root, and tests
H0: theta = theta_0 for any theta_0 in (0,1]. Unlike conventional panel
unit-root tests, which only test the extreme hypotheses that {it:all} units
are nonstationary or {it:all} are stationary, {cmd:xtmixedroot} quantifies
{it:how many} units are nonstationary, which is the quantity Pesaran (2012)
recommends reporting alongside any panel unit-root test.

{pstd}
The method exploits Ng's (2008) observation that in a panel mixing I(1) and
I(0) units the cross-sectional variance V_t grows linearly in t with slope
exactly theta (the "fanning out" of the distribution). Time-averaging the
first difference of V_t therefore estimates theta. Three estimators are
provided:

{phang2}o Estimator {bf:A} fits a unit-specific AR(p) by OLS, rescales each
series by D_i/sigma_i so that heterogeneous dynamics and innovation variances
do not contaminate the slope, and averages the change in the cross-sectional
variance of the rescaled panel. Inference uses a HAC t statistic.{p_end}

{phang2}o Estimator {bf:B} equals A but augments each AR regression with a
proxy for a common stationary factor (the cross-sectional average of the
differenced data and its lags, or the first principal component), which
removes the downward bias that cross-sectional correlation induces in
Estimator A.{p_end}

{phang2}o Estimator {bf:C} allows incidental linear trends y_it =
lambda_i*t + u_it: the AR regression includes a trend, and theta is the
intercept of a regression of the change in the cross-sectional variance on
(1, t^2-(t-1)^2). It converges much more slowly and needs very large N and
T.{p_end}

{pstd}
Because the Ng theta-hat requires a fairly long panel (T >= 100
recommended), {cmd:xtmixedroot} also always reports the Westerlund (2016)
bias-adjusted statistics, which are valid in short panels:
tau*_1,T is correctly sized for {it:any} T >= 2 and tests H0: theta = 1;
tau*_1,NT allows heterogeneous intercepts (larger T); tau*_1 is the
large-(N,T) simplification; and tau*_theta0 tests H0: theta = theta_0 < 1
when both N and T are large. When T < 25 the Ng block is skipped
automatically and only these statistics are shown.

{pstd}
Formulas, assumptions, and the full step-by-equation map from the code to
the two papers are documented in {helpb xtmixedroot_methods:help xtmixedroot methods}.


{marker options}{...}
{title:Options}

{dlgtab:Ng (2008) estimator}

{phang}
{opt estimator(a|b|c)} selects the Ng estimator. Default {cmd:a}. Use
{cmd:b} whenever cross-sectional correlation is suspected: Ng (2008) shows
that ignoring strong correlation biases theta-hat downward, while
controlling for correlation that is absent costs almost nothing. Use
{cmd:c} only when unit-specific linear trends are plausible and the panel is
very large (Ng recommends T >= 300, N >= 200).

{phang}
{opt lags(#)} fixes the AR order p for every unit (Ng's simulations use
p = 2). By default p is chosen unit-by-unit by the BIC over 1..{it:maxlags},
as in Ng's empirical applications.

{phang}
{opt maxlags(#)} sets the largest p considered by the BIC; default 4.

{phang}
{opt factors(#)} sets q, the number of lags of the factor proxy included in
the Estimator B regression; default 1, matching Ng's use of the current and
first lag of the cross-sectional average of the differenced data.

{phang}
{opt pc} proxies the common factor with the first principal component of the
differenced panel instead of the cross-sectional average. Ng reports that the
two proxies give similar results.

{phang}
{opt hac(#)} sets the Bartlett kernel truncation M for the HAC standard
error of theta-hat; default 2 (Ng's choice; her results for M = 1 and 4 are
similar).

{dlgtab:Hypothesis and inference}

{phang}
{opt theta0(#)} sets the null value. With {cmd:theta0(1)} (default) the
tests are left-tailed: rejection means some units are stationary. With
theta_0 < 1 the Ng t statistic and the Westerlund tau*_theta0 statistics are
two-sided. theta_0 = 0 is not testable (the limiting distribution collapses);
following Ng, test {cmd:theta0(.01)} instead: rejecting theta = .01 upward
also rejects theta = 0.

{phang}
{opt demean} estimates the Westerlund error variance and kurtosis from
cross-sectionally demeaned data, as Westerlund (2016, footnote 3) recommends
when common time effects are present. theta-hat itself is invariant to
common time effects.

{dlgtab:Reporting}

{phang}
{opt classify} orders the units by their estimated dominant autoregressive
root |phi_i1| and labels the top [theta-hat x N] units I(1), where [.] is the integer part
(Ng 2008, Sec. 4). This is a heuristic: Ng reports correct-classification rates of
about 60 percent in small samples and gives no formal theory for it. The
full classification is stored in {cmd:r(units)}.

{phang}
{opt graph} plots V_t for the raw and the rescaled panel together with the
straight line implied by theta-hat, the visual signature of the method: the
closer the panel is to all-I(1), the steeper the variance trend.


{marker interpret}{...}
{title:Interpreting the output}

{phang2}{bf:theta}: point estimate of the fraction of I(1) units, with HAC
standard error and confidence interval. Values near 0 mean the panel is
essentially stationary; near 1, essentially nonstationary; in between, the
panel is mixed and imposing homogeneous dynamics would be inappropriate.{p_end}

{phang2}{bf:implied number of I(1) units}: [theta-hat x N] (integer part).{p_end}

{phang2}{bf:H0: theta = theta_0}: the user's null, tested with the Ng HAC
t statistic (left-tailed at theta_0 = 1, two-sided otherwise).{p_end}

{phang2}{bf:H0: theta = 0.010 vs >}: "are there any I(1) units at all?" -
rejection implies theta > 0.{p_end}

{phang2}{bf:H0: theta = 1.000 vs <}: "are all units I(1)?" - the analogue of
a conventional panel unit-root null.{p_end}

{phang2}{bf:theta-hat (feasible, raw data)}: Westerlund's estimator, the
time-average of the change in the cross-sectional variance of the raw
(unrescaled) data. It estimates theta x sigma2_eps, hence the scaling by
s2_eps to obtain theta*.{p_end}

{phang2}{bf:theta*_BA}: bias-adjusted theta* (+ theta_0/T); with T fixed,
theta* is biased by exactly -theta_0/T.{p_end}

{phang2}{bf:tau*_1,T}: the headline short-panel statistic; correctly sized
for any T >= 2 provided intercepts are homogeneous (or the data are
cross-sectionally demeaned). Reject H0: theta = 1 when tau < -1.645 (5
percent).{p_end}

{phang2}{bf:tau*_1,NT}: adds the intercept-variance correction
4*s2_lambda/s2_eps; preferable when T is moderately large and intercepts are
heterogeneous.{p_end}

{phang2}{bf:tau*_theta0}: tests theta = theta_0 < 1; requires both N and T
large (Westerlund requires sqrt(N)/T -> 0) and is conservative in short
panels.{p_end}


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}{bf:Sample-size regimes.} T >= 100: trust theta-hat (Estimator A or B)
and all statistics. 25 <= T < 100: theta-hat is reported but is noisy; give
more weight to the Westerlund statistics. T < 25: only the Westerlund
statistics are computed; with T this small only H0: theta = 1 is testable
(tau*_1,T). N matters much less; N >= 30 suffices (Ng 2008).

{pstd}{bf:Which estimator.} In practice cross-sectional correlation is
rarely excludable, and Ng shows that controlling for it when it is absent is
nearly free while ignoring it when present biases theta-hat down. Estimator
B is therefore a sensible default in applications; A is the baseline that
matches the theory exactly.

{pstd}{bf:What theta-hat near 1 in a short panel does {it:not} mean.}
Westerlund (2016) proves that when the stationary units are local-to-unity
(alpha_i = exp(c_i/N^eta)), theta is not identified: theta-hat converges to
1 regardless of the true theta. A theta-hat near 1 is therefore evidence
that units are {it:persistent}, not necessarily that all of them have exact
unit roots. Larger T relaxes this: under joint asymptotics the test detects
alternatives as close as eta = gamma + 1/2, where T = N^gamma.

{pstd}{bf:Nonstationary common factors.} The method assumes any common
factor is {it:stationary} (Ng's A4). If a pervasive I(1) factor drives the
panel, every unit is nonstationary regardless of alpha_i, and theta is not
the object of interest; use the PANIC decomposition of Bai and Ng (2004)
instead.

{pstd}{bf:Variance components that grow like t.} If some other component of
the data has variance proportional to t (e.g. a common factor with F_t =
sqrt(t)), theta-hat estimates only an upper bound for theta - but such data
would violate every standard unit-root framework, not just this one (Ng
2008, Sec. 5).

{pstd}{bf:Deterministic time effects.} A common additive time effect a_t
leaves theta-hat unchanged. Unit-specific linear trends require Estimator C.
Note that C is far less precise (its rate is sqrt(N/T) rather than sqrt(N))
and Ng's own application found it unreliable at T = 25.

{pstd}{bf:Repeated AR roots.} The rescaling constant D_i is a product of
root differences and approaches 0 when the two largest estimated roots
nearly coincide; {cmd:xtmixedroot} floors |D_i| at 1e-6. Units with nearly
repeated dominant roots are rare in practice but can inflate the rescaled
variance; inspect {cmd:r(units)} if theta-hat looks anomalous.


{marker examples}{...}
{title:Examples}

{pstd}Baseline: what fraction of the panel variable y is nonstationary?{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtmixedroot y}{p_end}

{pstd}Control for cross-sectional correlation, classify the units, plot the
variance trend:{p_end}
{phang2}{cmd:. xtmixedroot y, estimator(b) classify graph}{p_end}

{pstd}Test that half the panel is nonstationary:{p_end}
{phang2}{cmd:. xtmixedroot y, theta0(.5)}{p_end}

{pstd}Short panel (T = 5): only H0: theta = 1 is testable:{p_end}
{phang2}{cmd:. xtmixedroot y}{p_end}
{phang2}(read the tau*_1,T line; the Ng block is skipped automatically){p_end}

{pstd}Fixed lag order and longer HAC window, as robustness:{p_end}
{phang2}{cmd:. xtmixedroot y, lags(2) hac(4)}{p_end}

{pstd}A full simulated validation of every code path against the Monte Carlo
designs of both source papers ships with the package:{p_end}
{phang2}{cmd:. net get xtmixedroot}{p_end}
{phang2}{cmd:. do xtmixedroot_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtmixedroot} stores the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}
{synopt:{cmd:r(theta)}}Ng theta-hat (Estimator A/B/C){p_end}
{synopt:{cmd:r(se_theta)}}HAC standard error of theta-hat{p_end}
{synopt:{cmd:r(t)}, {cmd:r(p)}}t statistic and p-value for H0: theta = theta_0{p_end}
{synopt:{cmd:r(t_low)}, {cmd:r(p_low)}}test of H0: theta = .01 vs > (any I(1) units){p_end}
{synopt:{cmd:r(t_all)}, {cmd:r(p_all)}}test of H0: theta = 1 vs < (all I(1) units){p_end}
{synopt:{cmd:r(N1hat)}}[theta-hat x N] (integer part){p_end}
{synopt:{cmd:r(p_mean)}}average selected AR lag order{p_end}
{synopt:{cmd:r(varlambda)}, {cmd:r(se_varlambda)}}variance of the incidental
trends and its s.e. (Estimator C only){p_end}
{synopt:{cmd:r(theta_w)}}Westerlund feasible theta-hat (raw data){p_end}
{synopt:{cmd:r(theta_star)}, {cmd:r(theta_ba)}}scaled and bias-adjusted theta{p_end}
{synopt:{cmd:r(sigma2e)}, {cmd:r(kappa)}, {cmd:r(sigma2lam)}}error variance,
error kurtosis, intercept variance{p_end}
{synopt:{cmd:r(tau1T)}, {cmd:r(p_tau1T)}}tau*_1,T and p-value (theta_0 = 1){p_end}
{synopt:{cmd:r(tau1NT)}, {cmd:r(p_tau1NT)}}tau*_1,NT and p-value (theta_0 = 1){p_end}
{synopt:{cmd:r(tau1)}, {cmd:r(p_tau1)}}tau*_1 and p-value (theta_0 = 1){p_end}
{synopt:{cmd:r(tautheta0)}, {cmd:r(p_tautheta0)}}tau*_theta0 and p-value (theta_0 < 1){p_end}
{synopt:{cmd:r(tautheta0NT)}, {cmd:r(p_tautheta0NT)}}sigma_theta,NT variant (theta_0 < 1){p_end}
{synopt:{cmd:r(theta0)}, {cmd:r(level)}}null value and confidence level{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(varname)}, {cmd:r(ivar)}, {cmd:r(tvar)},
{cmd:r(estimator)}}command, variable and setting names{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(V)}}T x 3: time, V_t of the raw data, V_t of the rescaled data{p_end}
{synopt:{cmd:r(units)}}N x 6 (sorted by |phi_i1| descending): unit id,
|phi_i1|, sigma_i, D_i, selected p, I(1) classification{p_end}


{marker references}{...}
{title:References}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and
cointegration. {it:Econometrica} 72: 1127-1177.{p_end}

{phang}Ng, S. 2008. A simple test for nonstationarity in mixed panels.
{it:Journal of Business & Economic Statistics} 26(1): 113-127.
{browse "https://doi.org/10.1198/073500106000000675"}{p_end}

{phang}Pesaran, M. H. 2012. On the interpretation of panel unit root tests.
{it:Economics Letters} 116: 545-546.{p_end}

{phang}Westerlund, J. 2016. A simple test for nonstationarity in mixed
panels: A further investigation. {it:Journal of Statistical Planning and
Inference} 173: 1-30.
{browse "https://doi.org/10.1016/j.jspi.2016.01.004"}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane"}{p_end}
