{smcl}
{* *! version 1.0.0  22may2026}{...}
{viewerjumpto "Syntax" "urtable##syntax"}{...}
{viewerjumpto "Description" "urtable##description"}{...}
{viewerjumpto "Options" "urtable##options"}{...}
{viewerjumpto "Methodology" "urtable##methodology"}{...}
{viewerjumpto "Examples" "urtable##examples"}{...}
{viewerjumpto "Stored results" "urtable##results"}{...}
{viewerjumpto "References" "urtable##references"}{...}
{viewerjumpto "Author" "urtable##author"}{...}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:urtable} {hline 2}}Joint ADF, DF-GLS, PP, and KPSS unit-root tests
with data-driven lag/bandwidth selection{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:urtable} {varname} {ifin}
[{cmd:,}
{opt l:ags(#)}
{opt t:rend}
{opt bgp(#)}
{opt rhoc:ap(#)}]

{phang}
{it:varname} must be tsset.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt l:ags(#)}}max lag for ADF BG search and DF-GLS criterion
search; default is the Schwert rule, floor(12*(T/100)^(1/4)).{p_end}
{synopt:{opt t:rend}}include a linear trend in the deterministic
component; default is constant only.{p_end}
{synopt:{opt bgp(#)}}Breusch-Godfrey p-value threshold used in the ADF
general-to-specific lag search; default is 0.10.{p_end}
{synopt:{opt rhoc:ap(#)}}cap on |rho_hat| in Andrews (1991) AR(1) plug-in
to avoid bandwidth blow-up near unit root; default is 0.97.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:urtable} reports four unit-root and stationarity tests on a single
time series in one comparison table: the augmented Dickey-Fuller (ADF), the
Elliott-Rothenberg-Stock GLS-detrended DF (DF-GLS) in three variants based
on different lag-selection criteria, the Phillips-Perron (PP), and the
Kwiatkowski-Phillips-Schmidt-Shin (KPSS) test. All lag lengths and
bandwidths are chosen data-driven. The output table includes critical
values at 1%, 5%, and 10%, decision flags, and a one-sentence conclusion at
the 5% level that aggregates the evidence across the four tests.

{pstd}
The command targets pedagogical use in time-series courses: every lag,
bandwidth, and decision is shown explicitly, and the underlying
methodology is documented in the footer of the output.


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets the maximum lag for the ADF BG search and the DF-GLS
criterion search. If omitted, the Schwert (1989) rule is applied:
floor(12*(T/100)^(1/4)). Note that PP and KPSS bandwidths are set by their
own data-driven Andrews (1991) procedure and do not use {opt lags()}.

{phang}
{opt trend} includes a linear time trend in the deterministic component
of each test. Without it, only a constant is included.

{phang}
{opt bgp(#)} controls the Breusch-Godfrey p-value threshold for the ADF
lag selection. The smallest k in [0, lags] with BG p-value above this
threshold is selected. Stricter thresholds (e.g., 0.05) tend to choose
shorter lags; looser thresholds (e.g., 0.15) tend to choose longer lags.

{phang}
{opt rhocap(#)} caps the absolute value of the AR(1) coefficient
estimated on test residuals when computing the Andrews (1991) Bartlett
bandwidth. Necessary because alpha(1) = 4*rho^2/(1-rho^2)^2 diverges as
|rho| approaches 1, which is common in KPSS residuals under H1.


{marker methodology}{...}
{title:Methodology}

{pstd}
{ul:ADF.} The dependent variable is Delta y_t. The regression is

{pmore}
Delta y_t = alpha (+ beta*t) + gamma*y_{t-1} + sum_{j=1}^k phi_j*Delta y_{t-j} + e_t

{pstd}
Lag k is chosen by a general-to-specific procedure (Hall 1994): for
k = 0, 1, ..., lags, the regression residuals are tested with the
Breusch-Godfrey LM test of order max(4, k+1). The smallest k with BG
p-value above {opt bgp()} is selected.

{pstd}
{ul:DF-GLS.} GLS detrending follows Elliott, Rothenberg, and Stock
(1996). With cbar = -7 (constant) or -13.5 (trend), the series and
regressors are quasi-differenced at alpha* = 1 + cbar/T. The resulting
GLS-detrended series y* is then used in an ADF-type regression without
constant or trend.

{pstd}
Three lag-selection criteria are reported as separate rows:

{phang2}
{it:ERS sequential-t}: starting from k = lags, the highest k whose lag
coefficient satisfies |t| > 1.645 (Ng-Perron 1995).

{phang2}
{it:Min SC}: argmin over k = 0..lags of ln(sigma^2) + (k+1)*ln(N)/N
(Schwarz / BIC).

{phang2}
{it:Min MAIC}: argmin of ln(sigma^2) + 2*(tau(k)+k)/N where
tau(k) = gamma^2 * sum(y*_{t-1})^2 / sigma^2 (Ng-Perron 2001).

{pstd}
All three regressions use a common sample (the maxlag sample) so that
the criteria are directly comparable.

{pstd}
DF-GLS critical values are from ERS (1996) Table 1, bracketed by sample
size (T<75, T<150, T<300, T>=300) for the trend case and the asymptotic
values for the constant-only case.

{pstd}
{ul:PP and KPSS.} Bandwidth is selected by the Andrews (1991) AR(1)
plug-in rule for the Bartlett kernel:

{pmore}
alpha(1) = 4*rho^2 / (1-rho^2)^2

{pmore}
BW = ceil(1.1447 * (alpha(1) * T)^(1/3))

{pstd}
For PP, rho is estimated from AR(1) applied to residuals of the PP-type
level regression (Delta y on y_{t-1} with constant/trend). For KPSS, rho
is from AR(1) on residuals of the level regression y on constant
(+trend). |rho| is capped at {opt rhocap()} and BW is capped at the
Schwert max.

{pstd}
The official ADF and PP statistics are taken from Stata's {cmd:dfuller}
and {cmd:pperron} at the selected lag/bandwidth. The KPSS statistic is
computed manually with a Bartlett kernel using the selected bandwidth.
The DF-GLS regressions and statistics are also computed manually, so
{cmd:urtable} does not depend on Stata's {cmd:dfgls} command.


{marker examples}{...}
{title:Examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. webuse air2}{p_end}
{phang2}{cmd:. tsset time}{p_end}

{pstd}Default model (constant only):{p_end}
{phang2}{cmd:. urtable air}{p_end}

{pstd}With a linear trend:{p_end}
{phang2}{cmd:. urtable air, trend}{p_end}

{pstd}Limit the ADF/DF-GLS lag search to 6:{p_end}
{phang2}{cmd:. urtable air, lags(6) trend}{p_end}

{pstd}Stricter BG threshold (prefer shorter ADF lags):{p_end}
{phang2}{cmd:. urtable air, bgp(0.05)}{p_end}

{pstd}Lower rho cap (more conservative Andrews bandwidth):{p_end}
{phang2}{cmd:. urtable air, rhocap(0.90)}{p_end}

{pstd}Test the first difference (should be stationary):{p_end}
{phang2}{cmd:. urtable D.air}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:urtable} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(adf_stat)}}ADF tau statistic{p_end}
{synopt:{cmd:r(adf_p)}}ADF MacKinnon p-value{p_end}
{synopt:{cmd:r(adf_lag)}}selected ADF lag{p_end}
{synopt:{cmd:r(adf_bg_p)}}BG p-value at selected lag{p_end}
{synopt:{cmd:r(pp_stat)}}PP tau statistic{p_end}
{synopt:{cmd:r(pp_p)}}PP p-value{p_end}
{synopt:{cmd:r(pp_lag)}}PP bandwidth{p_end}
{synopt:{cmd:r(pp_rho)}}capped AR(1) coefficient (PP residuals){p_end}
{synopt:{cmd:r(kpss_stat)}}KPSS LM statistic{p_end}
{synopt:{cmd:r(kpss_lag)}}KPSS bandwidth{p_end}
{synopt:{cmd:r(kpss_rho)}}capped AR(1) coefficient (KPSS residuals){p_end}
{synopt:{cmd:r(dfgls_ers_lag)}}DF-GLS lag selected by ERS seq-t{p_end}
{synopt:{cmd:r(dfgls_sc_lag)}}DF-GLS lag selected by Min SC{p_end}
{synopt:{cmd:r(dfgls_maic_lag)}}DF-GLS lag selected by Min MAIC{p_end}
{synopt:{cmd:r(dfgls_ers_stat)}}DF-GLS stat at ERS lag{p_end}
{synopt:{cmd:r(dfgls_sc_stat)}}DF-GLS stat at SC lag{p_end}
{synopt:{cmd:r(dfgls_maic_stat)}}DF-GLS stat at MAIC lag{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{synopt:{cmd:r(Ncommon)}}common sample size for DF-GLS{p_end}
{synopt:{cmd:r(lags)}}max lag used in search{p_end}
{synopt:{cmd:r(n_tau_reject_5)}}# of ADF/DF-GLS/PP rejecting H0 at 5%{p_end}
{synopt:{cmd:r(kpss_reject_5)}}1 if KPSS rejects H0 at 5%, else 0{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(model)}}"Constant" or "Constant + Trend"{p_end}
{synopt:{cmd:r(verdict)}}two-sentence conclusion text{p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. 1991. Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica} 59: 817-858.

{phang}
Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996. Efficient tests for
an autoregressive unit root. {it:Econometrica} 64: 813-836.

{phang}
Hall, A. 1994. Testing for a unit root in time series with pretest
data-based model selection. {it:Journal of Business and Economic
Statistics} 12: 461-470.

{phang}
Kwiatkowski, D., P. C. B. Phillips, P. Schmidt, and Y. Shin. 1992.
Testing the null hypothesis of stationarity against the alternative of a
unit root. {it:Journal of Econometrics} 54: 159-178.

{phang}
Levendis, J. D. 2018. {it:Time Series Econometrics: Learning Through
Replication}. 2nd ed. Springer.

{phang}
Ng, S., and P. Perron. 1995. Unit root tests in ARMA models with
data-dependent methods for the selection of the truncation lag.
{it:Journal of the American Statistical Association} 90: 268-281.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction
of unit root tests with good size and power. {it:Econometrica} 69:
1519-1554.

{phang}
Schwert, G. W. 1989. Tests for unit roots: A Monte Carlo investigation.
{it:Journal of Business and Economic Statistics} 7: 147-159.


{marker author}{...}
{title:Author}

{pstd}
Y. Baris Altayligil{break}
Istanbul University, Department of Economics{break}
{browse "mailto:ybaris@istanbul.edu.tr":ybaris@istanbul.edu.tr}

{pstd}
Please report bugs and suggestions by email. Source and updates are also
available at the author's repository (see SSC package description).


{title:Also see}

{psee}
Online: {help dfuller}, {help dfgls}, {help pperron}, {help kpss} (if
installed via {stata "ssc install kpss"})
{p_end}
